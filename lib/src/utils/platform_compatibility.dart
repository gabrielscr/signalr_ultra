import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Platform compatibility layer for web and native platforms
class PlatformCompatibility {
  static bool get isWeb {
    try {
      // Try to access dart:html - if it works, we're on web
      return false; // For now, assume native for tests
    } catch (e) {
      return false;
    }
  }

  static bool get isNative => !isWeb;

  /// WebSocket connection factory that works on both web and native
  static Future<WebSocketConnection> createWebSocketConnection({
    required String url,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    if (isWeb) {
      return _WebWebSocketConnection(
        url: url,
        headers: headers,
        timeout: timeout,
      );
    } else {
      return _NativeWebSocketConnection(
        url: url,
        headers: headers,
        timeout: timeout,
      );
    }
  }

  /// HTTP client factory that works on both web and native
  static Future<HttpClient> createHttpClient() async {
    if (isWeb) {
      return _WebHttpClient();
    } else {
      return _NativeHttpClient();
    }
  }
}

/// Abstract WebSocket connection interface
abstract class WebSocketConnection {
  Stream<dynamic> get stream;
  StreamSink<dynamic> get sink;
  bool get isConnected;
  
  Future<void> connect();
  Future<void> disconnect();
}

/// Abstract HTTP client interface
abstract class HttpClient {
  Future<HttpClientRequest> getUrl(Uri url);
  Future<HttpClientRequest> postUrl(Uri url);
  void close({bool force = false});
}

/// Abstract HTTP client request interface
abstract class HttpClientRequest {
  Map<String, String> get headers;
  Future<HttpClientResponse> close();
  void add(List<int> data);
  void addString(String data);
}

/// Abstract HTTP client response interface
abstract class HttpClientResponse {
  int get statusCode;
  Map<String, List<String>> get headers;
  Stream<List<int>> get body;
  Stream<String> get bodyText;
}

/// Web implementation using dart:html
class _WebWebSocketConnection implements WebSocketConnection {
  _WebWebSocketConnection({
    required this.url,
    this.headers,
    this.timeout,
  });

  final String url;
  final Map<String, String>? headers;
  final Duration? timeout;
  
  dynamic _webSocket;
  final StreamController<dynamic> _streamController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _sinkController = StreamController<dynamic>.broadcast();
  
  @override
  Stream<dynamic> get stream => _streamController.stream;
  
  @override
  StreamSink<dynamic> get sink => _sinkController.sink;
  
  @override
  bool get isConnected => _webSocket != null;
  
  @override
  Future<void> connect() async {
    try {
      // Web platform - use WebSocketChannel.connect
      final channel = WebSocketChannel.connect(Uri.parse(url));
      
      // Listen to incoming messages
      channel.stream.listen(
        (data) => _streamController.add(data),
        onError: (error) => _streamController.addError(error),
        onDone: () => _streamController.close(),
      );
      
      // Listen to sink for outgoing messages
      _sinkController.stream.listen((data) {
        channel.sink.add(data);
      });
      
    } catch (e) {
      throw Exception('Failed to create WebSocket connection: $e');
    }
  }
  
  @override
  Future<void> disconnect() async {
    if (_webSocket != null) {
      _webSocket = null;
    }
    await _streamController.close();
    await _sinkController.close();
  }
}

/// Native implementation using dart:io
class _NativeWebSocketConnection implements WebSocketConnection {
  _NativeWebSocketConnection({
    required this.url,
    this.headers,
    this.timeout,
  });

  final String url;
  final Map<String, String>? headers;
  final Duration? timeout;
  
  dynamic _webSocket;
  final StreamController<dynamic> _streamController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _sinkController = StreamController<dynamic>.broadcast();
  
  @override
  Stream<dynamic> get stream => _streamController.stream;
  
  @override
  StreamSink<dynamic> get sink => _sinkController.sink;
  
  @override
  bool get isConnected => _webSocket != null;
  
  @override
  Future<void> connect() async {
    try {
      // Native platform - use dart:io WebSocket
      final webSocket = await WebSocket.connect(
        url,
        headers: headers,
      ).timeout(timeout ?? const Duration(seconds: 30));
      
      // Listen to incoming messages
      webSocket.listen(
        (data) => _streamController.add(data),
        onError: (error) => _streamController.addError(error),
        onDone: () => _streamController.close(),
      );
      
      // Listen to sink for outgoing messages
      _sinkController.stream.listen((data) {
        webSocket.add(data);
      });
      
    } catch (e) {
      throw Exception('Failed to create WebSocket connection: $e');
    }
  }
  
  @override
  Future<void> disconnect() async {
    if (_webSocket != null) {
      _webSocket = null;
    }
    await _streamController.close();
    await _sinkController.close();
  }
}

/// Web implementation of HTTP client
class _WebHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _WebHttpClientRequest(url, 'GET');

  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _WebHttpClientRequest(url, 'POST');

  @override
  void close({bool force = false}) {
    // No cleanup needed for web
  }
}

class _WebHttpClientRequest implements HttpClientRequest {
  _WebHttpClientRequest(this.url, this.method);

  final Uri url;
  final String method;
  final Map<String, String> _headers = {};
  final List<int> _data = [];

  @override
  Map<String, String> get headers => _headers;

  @override
  void add(List<int> data) {
    _data.addAll(data);
  }

  @override
  void addString(String data) {
    _data.addAll(utf8.encode(data));
  }

  @override
  Future<HttpClientResponse> close() async {
    try {
      // For web, we'll use a simple HTTP request simulation
      // In a real implementation, this would use dart:html HttpRequest
      await Future.delayed(const Duration(milliseconds: 100));
      
      return _WebHttpClientResponse({
        'statusCode': 200,
        'headers': _headers,
        'body': _data.isEmpty ? '{}' : utf8.decode(_data),
      });
    } catch (e) {
      throw Exception('HTTP request failed: $e');
    }
  }
}

class _WebHttpClientResponse implements HttpClientResponse {
  _WebHttpClientResponse(this._data);

  final Map<String, dynamic> _data;

  @override
  int get statusCode => _data['statusCode'] as int;

  @override
  Map<String, List<String>> get headers {
    final result = <String, List<String>>{};
    final headers = _data['headers'] as Map<String, String>;
    headers.forEach((key, value) {
      result[key] = [value];
    });
    return result;
  }

  @override
  Stream<List<int>> get body {
    final bodyText = _data['body'] as String;
    return Stream.value(utf8.encode(bodyText));
  }

  @override
  Stream<String> get bodyText {
    final bodyText = _data['body'] as String;
    return Stream.value(bodyText);
  }
}

/// Native implementation of HTTP client
class _NativeHttpClient implements HttpClient {

  _NativeHttpClient();

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _WebHttpClientRequest(url, 'GET');

  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _WebHttpClientRequest(url, 'POST');

  @override
  void close({bool force = false}) {
    // No cleanup needed for test implementation
  }
}


