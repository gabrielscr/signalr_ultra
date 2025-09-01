import 'dart:async';
import 'dart:typed_data';

import '../core/domain/interfaces/transport_interface.dart';
import '../core/logging/signalr_logger.dart';
import '../utils/platform_compatibility.dart';

/// WebSocket transport implementation using web_socket_channel
class WebSocketTransport implements TransportInterface {
  WebSocketTransport({
    required SignalRLogger logger,
    Map<String, String>? headers,
    Duration? timeout,
  }) : _logger = logger,
       _headers = headers ?? {},
       _timeout = timeout ?? const Duration(seconds: 30);

  final SignalRLogger _logger;
  final Map<String, String> _headers;
  final Duration _timeout;
  
  WebSocketConnection? _platformConnection;
  StreamSubscription? _subscription;
  final StreamController<dynamic> _dataController = StreamController<dynamic>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  bool _isConnected = false;
  String? _currentUrl;

  @override
  TransportType get type => TransportType.webSocket;

  @override
  List<TransferFormat> get supportedFormats => [TransferFormat.text, TransferFormat.binary];

  @override
  Future<void> connect({
    required String url,
    Map<String, String>? headers,
    TransferFormat format = TransferFormat.text,
  }) async {
    if (_isConnected) {
      throw Exception('WebSocket transport already connected');
    }

    _currentUrl = url;
    _logger.transport('Connecting to WebSocket', type: 'WEBSOCKET', operation: 'CONNECT', data: {'url': url});

    try {
      // Convert HTTP URL to WebSocket URL (http:// -> ws://, https:// -> wss://)
      final wsUrl = url.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      
      // Use platform-compatible WebSocket connection
      final webSocketConnection = await PlatformCompatibility.createWebSocketConnection(
        url: wsUrl,
        headers: {..._headers, ...?headers},
        timeout: _timeout,
      );
      
      await webSocketConnection.connect();
      
      // Store the platform-compatible connection directly
      _platformConnection = webSocketConnection;

      _isConnected = true;
      _connectionController.add(true);
      
      _logger.transport('WebSocket connection established', type: 'WEBSOCKET', operation: 'CONNECTED');

      // Listen to WebSocket messages
      _subscription = _platformConnection!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

    } catch (e) {
      _logger.error('WebSocket connection failed', exception: e);
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _logger.transport('Disconnecting WebSocket transport', type: 'WEBSOCKET', operation: 'DISCONNECT');
    
    _isConnected = false;
    _connectionController.add(false);
    
    await _subscription?.cancel();
    _subscription = null;
    
    await _platformConnection?.disconnect();
    _platformConnection = null;
    
    _logger.transport('WebSocket transport disconnected', type: 'WEBSOCKET', operation: 'DISCONNECTED');
  }

  @override
  Future<void> send(dynamic data) async {
    if (!_isConnected) {
      throw Exception('WebSocket transport not connected');
    }

    try {
      if (data is String) {
        _platformConnection!.sink.add(data);
        _logger.transport('WebSocket text message sent', type: 'WEBSOCKET', operation: 'SEND', data: {'data': data});
      } else if (data is List<int>) {
        _platformConnection!.sink.add(data);
        _logger.transport('WebSocket binary message sent', type: 'WEBSOCKET', operation: 'SEND', data: {'size': data.length});
      } else {
        // Convert to string if possible
        final stringData = data.toString();
        _platformConnection!.sink.add(stringData);
        _logger.transport('WebSocket message sent (converted)', type: 'WEBSOCKET', operation: 'SEND', data: {'data': stringData});
      }
    } catch (e) {
      _logger.error('WebSocket send failed', exception: e);
      rethrow;
    }
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

  /// Handles incoming WebSocket messages with type detection and parsing
  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        // Para SignalR, sempre enviar como string, não fazer parse do JSON aqui
        _dataController.add(message);
        _logger.transport('WebSocket message received', type: 'WEBSOCKET', operation: 'RECEIVE', data: {'data': message});
      } else if (message is List<int>) {
        // Binary message - converter para Uint8List
        _dataController.add(Uint8List.fromList(message));
        _logger.transport('WebSocket binary message received', type: 'WEBSOCKET', operation: 'RECEIVE', data: {'size': message.length});
      } else {
        // Other types - converter para string
        _dataController.add(message.toString());
        _logger.transport('WebSocket message received (converted)', type: 'WEBSOCKET', operation: 'RECEIVE', data: {'type': message.runtimeType});
      }
    } catch (e) {
      _logger.error('Error handling WebSocket message', exception: e);
    }
  }

  void _handleError(Object error) {
    _logger.error('WebSocket transport error', exception: error);
    _isConnected = false;
    _connectionController.add(false);
    _dataController.addError(error);
  }

  void _handleDone() {
    _logger.transport('WebSocket stream ended', type: 'WEBSOCKET', operation: 'DONE');
    _isConnected = false;
    _connectionController.add(false);
    _dataController.close();
  }
}
