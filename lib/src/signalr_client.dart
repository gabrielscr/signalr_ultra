import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'core/domain/entities/connection_state.dart';
import 'core/domain/repositories/connection_repository.dart';
import 'core/domain/interfaces/transport_interface.dart';
import 'core/domain/interfaces/protocol_interface.dart';
import 'core/domain/interfaces/retry_interface.dart';
import 'core/domain/interfaces/observability_interface.dart';
import 'utils/platform_compatibility.dart';
import 'utils/web_http_client.dart' as web;
import 'package:flutter/foundation.dart';

/// Ultra power SignalR client with auto-healing and zero maintenance
class SignalRClient implements ConnectionRepository {
  SignalRClient({
    required TransportInterface transport,
    required ProtocolInterface protocol,
    required CircuitBreaker circuitBreaker,
    required ObservabilityInterface observability,
  })  : _transport = transport,
        _protocol = protocol,
        _circuitBreaker = circuitBreaker,
        _observability = observability {
    _setupTransportListeners();
  }

  final TransportInterface _transport;
  final ProtocolInterface _protocol;
  final CircuitBreaker _circuitBreaker;
  final ObservabilityInterface _observability;

  ConnectionState _state = ConnectionState.disconnected;
  ConnectionMetadata? _metadata;
  final StreamController<ConnectionState> _stateController = StreamController<ConnectionState>.broadcast();
  final StreamController<ConnectionMetadata> _metadataController = StreamController<ConnectionMetadata>.broadcast();

  // Method handlers for incoming invocations
  final Map<String, List<Function(List<dynamic>)>> _methodHandlers = {};
  // Pending invocations waiting for completion
  final Map<String, Completer<dynamic>> _pendingInvocations = {};
  // Active streaming invocations
  final Map<String, StreamController<dynamic>> _streamControllers = {};

  int _invocationId = 0;
  Timer? _pingTimer;
  Timer? _keepAliveTimer;
  StreamSubscription<dynamic>? _transportSubscription;

  @override
  Future<ConnectionMetadata> connect({
    required String url,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final timer = _observability.startTimer('connection_attempt');

    try {
      _updateState(ConnectionState.connecting);

      // Step 1: Perform HTTP negotiation
      final negotiationResult = await _performNegotiation(url, headers);
      _observability.log(LogLevel.info, 'Negotiation completed', {
        'connectionId': negotiationResult['connectionId'],
        'availableTransports': negotiationResult['availableTransports'],
      });

      // Step 2: Connect transport with negotiated connection
      await _circuitBreaker.execute(() async {
        await _transport.connect(
          url: url,
          headers: headers,
          format: _protocol.transferFormat,
        );
      });

      // Step 3: Perform handshake with the SignalR hub
      final handshakeRequest = _protocol.createHandshakeRequest();
      _observability.log(LogLevel.info, 'Sending handshake request', {
        'request': utf8.decode(handshakeRequest),
      });
      await _transport.send(handshakeRequest);

      // Wait for handshake response with timeout
      final handshakeCompleter = Completer<bool>();
      final handshakeSubscription = _transport.dataStream.listen((data) {
        try {
          _observability.log(LogLevel.info, 'Received handshake response data', {
            'type': data.runtimeType.toString(),
            'data': data.toString(),
          });
          
          Uint8List dataBytes;
          if (data is String) {
            dataBytes = Uint8List.fromList(utf8.encode(data));
            _observability.log(LogLevel.info, 'Converted String to Uint8List', {
              'length': dataBytes.length,
            });
          } else if (data is Uint8List) {
            dataBytes = data;
            _observability.log(LogLevel.info, 'Using Uint8List directly', {
              'length': dataBytes.length,
            });
          } else {
            _observability.logError('Invalid data type for handshake response', Exception('Expected String or Uint8List, got ${data.runtimeType}'));
            return;
          }
          
          final handshakeResult = _protocol.parseHandshakeResponse(dataBytes);
          _observability.log(LogLevel.info, 'Handshake response parsed', {
            'result': handshakeResult,
          });
          
          if (handshakeResult) {
            handshakeCompleter.complete(true);
          }
        } catch (e) {
          _observability.logError('Error parsing handshake response', e);
        }
      });

      await handshakeCompleter.future.timeout(
        timeout ?? const Duration(seconds: 30),
      );

      await handshakeSubscription.cancel();

      _updateState(ConnectionState.connected);
      _startKeepAlive();

      final metadata = ConnectionMetadata(
        connectionId: negotiationResult['connectionId'] ?? _generateConnectionId(),
        baseUrl: url,
        connectedAt: DateTime.now(),
        uptime: Duration.zero,
      );

      _updateMetadata(metadata);
      timer.stop();

      _observability.log(LogLevel.info, 'Connected to SignalR hub', {
        'url': url,
        'connectionId': metadata.connectionId,
      });

      return metadata;
    } catch (e) {
      timer.stop();
      _updateState(ConnectionState.failed);

      _observability.logError('Failed to connect to SignalR hub', e);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _updateState(ConnectionState.disconnecting);

    _pingTimer?.cancel();
    _keepAliveTimer?.cancel();
    await _transportSubscription?.cancel();

    // Send close message to gracefully terminate connection
    final closeMessage = _protocol.writeMessage(
      CompletionMessage(invocationId: null, error: 'Connection closed'),
    );

    try {
      await _transport.send(closeMessage);
    } catch (e) {
      // Ignore errors during disconnect
    }

    await _transport.disconnect();
    _updateState(ConnectionState.disconnected);

    _observability.log(LogLevel.info, 'Disconnected from SignalR hub');
  }

  @override
  Future<void> sendMessage({
    required String method,
    List<dynamic>? arguments,
    Map<String, String>? headers,
  }) async {
    if (!isConnected) {
      throw Exception('Not connected to hub');
    }

    final message = InvocationMessage(
      target: method,
      arguments: arguments,
      headers: headers,
    );

    final data = _protocol.writeMessage(message);
    await _transport.send(data);

    _observability.incrementCounter('messages_sent', {'method': method});
  }

  @override
  Future<T> invoke<T>({
    required String method,
    List<dynamic>? arguments,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    if (!isConnected) {
      throw Exception('Not connected to hub');
    }

    final invocationId = _generateInvocationId();
    final completer = Completer<T>();
    _pendingInvocations[invocationId] = completer;

    final message = InvocationMessage(
      target: method,
      arguments: arguments,
      invocationId: invocationId,
      headers: headers,
    );

    final data = _protocol.writeMessage(message);
    await _transport.send(data);

    final result = await completer.future.timeout(
      timeout ?? const Duration(seconds: 30),
    );

    _pendingInvocations.remove(invocationId);
    return result;
  }

  @override
  Stream<dynamic> stream({
    required String method,
    List<dynamic>? arguments,
    Map<String, String>? headers,
  }) {
    if (!isConnected) {
      throw Exception('Not connected to hub');
    }

    final invocationId = _generateInvocationId();
    final controller = StreamController<dynamic>();
    _streamControllers[invocationId] = controller;

    final message = InvocationMessage(
      target: method,
      arguments: arguments,
      invocationId: invocationId,
      headers: headers,
    );

    final data = _protocol.writeMessage(message);
    _transport.send(data);

    return controller.stream;
  }

  @override
  void on(String method, Function(List<dynamic> arguments) handler) {
    _methodHandlers.putIfAbsent(method, () => []).add(handler);
  }

  @override
  void off(String method) {
    _methodHandlers.remove(method);
  }

  @override
  ConnectionState get state => _state;

  @override
  Stream<ConnectionState> get stateStream => _stateController.stream;

  @override
  ConnectionMetadata? get metadata => _metadata;

  @override
  Stream<ConnectionMetadata> get metadataStream => _metadataController.stream;

  @override
  bool get isConnected => _state == ConnectionState.connected;

  @override
  Map<String, dynamic> get statistics => {
        'state': _state.toString(),
        'isConnected': isConnected,
        'pendingInvocations': _pendingInvocations.length,
        'activeStreams': _streamControllers.length,
        'methodHandlers': _methodHandlers.length,
        'circuitBreaker': _circuitBreaker.statistics,
        'metrics': _observability.metrics,
      };

  void _setupTransportListeners() {
    _transportSubscription = _transport.dataStream.listen(
      _handleTransportData,
      onError: _handleTransportError,
      onDone: _handleTransportDone,
    );
  }

  /// Performs HTTP negotiation with the SignalR hub
  Future<Map<String, dynamic>> _performNegotiation(String url, Map<String, String>? headers) async {
    try {
      // Extract base URL and hub path
      final uri = Uri.parse(url);
      final baseUrl = 'http://${uri.host}:${uri.port}'; // Always use HTTP for negotiation
      final hubPath = uri.path;
      
      // Create negotiation URL
      final negotiationUrl = '$baseUrl$hubPath/negotiate';
      
      _observability.log(LogLevel.info, 'Starting negotiation', {
        'negotiationUrl': negotiationUrl,
      });

      // Use web-specific implementation for Flutter Web
      if (kIsWeb) {
        _observability.log(LogLevel.info, 'Using web-specific HTTP client');
        
        final negotiationData = await web.WebHttpClient.post(
          negotiationUrl,
          headers: headers,
          body: '{}',
          timeout: const Duration(seconds: 10),
        );
        
        _observability.log(LogLevel.info, 'Web negotiation completed', {
          'connectionId': negotiationData['connectionId'],
        });
        
        return negotiationData;
      } else {
        // Use platform compatibility for native platforms
        final client = await PlatformCompatibility.createHttpClient();
        
        try {
          // Create request
          final request = await client.postUrl(Uri.parse(negotiationUrl));
          
          // Add headers
          request.headers['Content-Type'] = 'application/json';
          if (headers != null) {
            headers.forEach((key, value) {
              request.headers[key] = value;
            });
          }
          
          // Send empty body
          request.addString('{}');
          
          // Get response with timeout
          final response = await request.close().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Negotiation request timed out after 10 seconds');
            },
          );
          
          // Read response body with timeout
          final responseBody = await response.bodyText.join().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Response body read timed out after 5 seconds');
            },
          );
          
          _observability.log(LogLevel.info, 'Negotiation response received', {
            'statusCode': response.statusCode,
            'responseBody': responseBody,
          });
          
          if (response.statusCode == 200) {
            final negotiationData = jsonDecode(responseBody) as Map<String, dynamic>;
            return negotiationData;
          } else {
            throw Exception('Negotiation failed with status ${response.statusCode}: $responseBody');
          }
        } finally {
          client.close();
        }
      }
    } catch (e) {
      _observability.logError('Negotiation failed', e);
      rethrow;
    }
  }

  void _handleTransportData(dynamic data) {
    try {
      Uint8List dataBytes;
      if (data is String) {
        dataBytes = Uint8List.fromList(utf8.encode(data));
      } else if (data is Uint8List) {
        dataBytes = data;
      } else {
        _observability.logError('Invalid data type for transport data', Exception('Expected String or Uint8List, got ${data.runtimeType}'));
        return;
      }
      
      final messages = _protocol.parseMessages(dataBytes);
      messages.forEach(_handleMessage);
      _observability.incrementCounter('messages_received');
    } catch (e) {
      _observability.logError('Failed to parse transport data', e);
    }
  }

  void _handleMessage(SignalRMessage message) {
    switch (message.type) {
      case MessageType.invocation:
        _handleInvocation(message as InvocationMessage);
        break;
      case MessageType.completion:
        _handleCompletion(message as CompletionMessage);
        break;
      case MessageType.streamItem:
        _handleStreamItem(message);
        break;
      case MessageType.ping:
        _handlePing();
        break;
      default:
        _observability.log(LogLevel.debug, 'Unhandled message type: ${message.type}');
    }
  }

  void _handleInvocation(InvocationMessage message) {
    final handlers = _methodHandlers[message.target];
    if (handlers != null) {
      handlers.forEach((handler) {
        try {
          handler(message.arguments ?? []);
        } catch (e) {
          _observability.logError('Error in method handler: ${message.target}', e);
        }
      });
    }
  }

  void _handleCompletion(CompletionMessage message) {
    if (message.invocationId != null) {
      final completer = _pendingInvocations[message.invocationId];
      if (completer != null) {
        if (message.error != null) {
          completer.completeError(Exception(message.error));
        } else {
          completer.complete(message.result);
        }
      }

      final streamController = _streamControllers[message.invocationId];
      if (streamController != null) {
        if (message.error != null) {
          streamController.addError(Exception(message.error));
        }
        streamController.close();
        _streamControllers.remove(message.invocationId);
      }
    }
  }

  void _handleStreamItem(SignalRMessage message) {
    _observability.log(LogLevel.debug, 'Received stream item');
  }

  void _handlePing() {
    // Respond to ping with pong to maintain connection
    try {
      final pongMessage = _protocol.writeMessage(
        CompletionMessage(invocationId: null),
      );
      // Fire and forget - don't await to avoid blocking
      _transport.send(pongMessage).catchError((error) {
        _observability.logError('Failed to send pong message', error);
      });
    } catch (e) {
      _observability.logError('Failed to create pong message', e);
    }
  }

  void _handleTransportError(Object error) {
    _observability.logError('Transport error', error);
    _updateState(ConnectionState.failed);
  }

  void _handleTransportDone() {
    _observability.log(LogLevel.info, 'Transport connection closed');
    _updateState(ConnectionState.disconnected);
  }

  void _updateState(ConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);

      _observability.log(LogLevel.info, 'Connection state changed', {
        'from': _state.toString(),
        'to': newState.toString(),
      });
    }
  }

  void _updateMetadata(ConnectionMetadata newMetadata) {
    _metadata = newMetadata;
    _metadataController.add(newMetadata);
  }

  void _startKeepAlive() {
    // Send ping every 15 seconds to keep connection alive
    _pingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (isConnected) {
        _sendKeepAlive();
      } else {
        timer.cancel();
      }
    });

    // Update uptime every second
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_metadata != null) {
        final newUptime = DateTime.now().difference(_metadata!.connectedAt);
        _updateMetadata(_metadata!.copyWith(uptime: newUptime));
      }
    });
  }

  void _sendKeepAlive() {
    try {
      final pingMessage = _protocol.writeMessage(
        CompletionMessage(invocationId: null),
      );
      // Fire and forget - don't await to avoid blocking
      _transport.send(pingMessage).catchError((error) {
        _observability.logError('Failed to send keep-alive ping', error);
      });
    } catch (e) {
      _observability.logError('Failed to create keep-alive ping', e);
    }
  }

  String _generateConnectionId() => 'conn_${DateTime.now().millisecondsSinceEpoch}_${_invocationId++}';

  String _generateInvocationId() => 'inv_${DateTime.now().millisecondsSinceEpoch}_${_invocationId++}';
}
