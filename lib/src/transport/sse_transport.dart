import 'dart:async';
import 'dart:convert';

import '../core/domain/interfaces/transport_interface.dart';
import '../core/logging/signalr_logger.dart';
import '../utils/platform_compatibility.dart';

/// Implementação própria de Server-Sent Events (SSE)
class SSETransport implements TransportInterface {

  SSETransport({
    required SignalRLogger logger,
    Map<String, String>? headers,
    Duration? timeout,
  }) : _logger = logger,
       _headers = headers ?? {};
  final SignalRLogger _logger;
  final Map<String, String> _headers;
  
  HttpClient? _client;
  HttpClientRequest? _request;
  HttpClientResponse? _response;
  StreamSubscription<String>? _subscription;
  final StreamController<dynamic> _dataController = StreamController<dynamic>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  bool _isConnected = false;
  String? _currentUrl;

  @override
  TransportType get type => TransportType.serverSentEvents;

  @override
  List<TransferFormat> get supportedFormats => [TransferFormat.text];

  @override
  Future<void> connect({
    required String url,
    Map<String, String>? headers,
    TransferFormat format = TransferFormat.text,
  }) async {
    if (_isConnected) {
      throw Exception('SSE transport already connected');
    }

    if (format != TransferFormat.text) {
      throw Exception('SSE transport only supports text format');
    }

    _currentUrl = url;
    _logger.transport('Connecting to SSE endpoint', type: 'SSE', operation: 'CONNECT', data: {'url': url});

    try {
      _client = await PlatformCompatibility.createHttpClient();
      
      // Create request
      final uri = Uri.parse(url);
      _request = await _client!.getUrl(uri);
      
      // Set headers
      _request!.headers['Accept'] = 'text/event-stream';
      _request!.headers['Cache-Control'] = 'no-cache';
      _request!.headers['Connection'] = 'keep-alive';
      
      // Add custom headers
      for (final entry in _headers.entries) {
        _request!.headers[entry.key] = entry.value;
      }
      
      if (headers != null) {
        for (final entry in headers.entries) {
          _request!.headers[entry.key] = entry.value;
        }
      }

      // Send request
      _response = await _request!.close();
      
      if (_response!.statusCode != 200) {
        throw Exception('SSE connection failed with status: ${_response!.statusCode}');
      }

      _isConnected = true;
      _connectionController.add(true);
      
      _logger.transport('SSE connection established', type: 'SSE', operation: 'CONNECTED');

      // Start listening to SSE stream
      _subscription = _response!.bodyText.transform(const LineSplitter()).listen(
        _handleSSEMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

    } catch (e) {
      _logger.error('SSE connection failed', exception: e);
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _logger.transport('Disconnecting SSE transport', type: 'SSE', operation: 'DISCONNECT');
    
    _isConnected = false;
    _connectionController.add(false);
    
    await _subscription?.cancel();
    _subscription = null;
    
    _request = null;
    
    _response = null;
    
    _client?.close();
    _client = null;
    
    _logger.transport('SSE transport disconnected', type: 'SSE', operation: 'DISCONNECTED');
  }

  @override
  Future<void> send(dynamic data) async {
    if (!_isConnected) {
      throw Exception('SSE transport not connected');
    }

    // SSE is unidirectional - we can't send data back through the same connection
    // For SignalR, we need to use a separate HTTP POST request for sending data
    _logger.transport('SSE send not supported - use separate HTTP request', 
                     type: 'SSE', operation: 'SEND', data: {'data': data});
    
    throw UnsupportedError('SSE transport is read-only. Use HTTP POST for sending data.');
  }

  @override
  Stream<dynamic> get dataStream => _dataController.stream;

  @override
  Stream<bool> get connectionStateStream => _connectionController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  String? get url => _currentUrl;

  @override
  Map<String, String> get headers => Map.from(_headers);

  void _handleSSEMessage(String line) {
    try {
      if (line.isEmpty) {
        // Empty line indicates end of message
        return;
      }

      if (line.startsWith('data: ')) {
        final data = line.substring(6); // Remove 'data: ' prefix
        
        if (data == '[DONE]') {
          // Server sent end signal
          _logger.transport('SSE stream ended by server', type: 'SSE', operation: 'END');
          _handleDone();
          return;
        }

        // Parse the data
        try {
          final parsedData = jsonDecode(data);
          _dataController.add(parsedData);
          _logger.transport('SSE data received', type: 'SSE', operation: 'RECEIVE', data: {'data': parsedData});
        } catch (e) {
          // If not JSON, send as string
          _dataController.add(data);
          _logger.transport('SSE text data received', type: 'SSE', operation: 'RECEIVE', data: {'data': data});
        }
      } else if (line.startsWith('event: ')) {
        final event = line.substring(7); // Remove 'event: ' prefix
        _logger.transport('SSE event received', type: 'SSE', operation: 'EVENT', data: {'event': event});
      } else if (line.startsWith('id: ')) {
        final id = line.substring(4); // Remove 'id: ' prefix
        _logger.transport('SSE message ID', type: 'SSE', operation: 'ID', data: {'id': id});
      } else if (line.startsWith('retry: ')) {
        final retry = line.substring(7); // Remove 'retry: ' prefix
        _logger.transport('SSE retry directive', type: 'SSE', operation: 'RETRY', data: {'retry': retry});
      }
      
    } catch (e) {
      _logger.error('Error handling SSE message', exception: e);
    }
  }

  void _handleError(Object error) {
    _logger.error('SSE transport error', exception: error);
    _isConnected = false;
    _connectionController.add(false);
    _dataController.addError(error);
  }

  void _handleDone() {
    _logger.transport('SSE stream ended', type: 'SSE', operation: 'DONE');
    _isConnected = false;
    _connectionController.add(false);
    _dataController.close();
  }

  /// Helper method to send data via HTTP POST (for SignalR compatibility)
  Future<String> sendViaHttp(String data) async {
    if (_currentUrl == null) {
      throw Exception('No URL available for HTTP send');
    }

    try {
      final client = await PlatformCompatibility.createHttpClient();
      final request = await client.postUrl(Uri.parse(_currentUrl!));
      
      // Set headers
      request.headers['Content-Type'] = 'application/json';
      for (final entry in _headers.entries) {
        request.headers[entry.key] = entry.value;
      }
      
      // Send data
      request.addString(data);
      final response = await request.close();
      
      // Read response
      final responseData = await response.bodyText.join();
      
      _logger.transport('HTTP send completed', type: 'HTTP', operation: 'SEND', data: {
        'statusCode': response.statusCode,
        'response': responseData,
      });
      
      return responseData;
      
    } catch (e) {
      _logger.error('HTTP send failed', exception: e);
      rethrow;
    }
  }
}
