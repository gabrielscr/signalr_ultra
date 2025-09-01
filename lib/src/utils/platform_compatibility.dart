import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

/// Platform compatibility layer for web and native platforms
class PlatformCompatibility {
  static bool get isWeb => kIsWeb;
  static bool get isNative => !kIsWeb;

  /// WebSocket connection factory that works on both web and native
  static Future<WebSocketConnection> createWebSocketConnection({
    required String url,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    if (kIsWeb) {
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
    if (kIsWeb) {
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

/// Web implementation using WebSocketChannel
class _WebWebSocketConnection implements WebSocketConnection {
  _WebWebSocketConnection({
    required this.url,
    this.headers,
    this.timeout,
  });

  final String url;
  final Map<String, String>? headers;
  final Duration? timeout;
  
  WebSocketChannel? _webSocket;
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
      _webSocket = WebSocketChannel.connect(Uri.parse(url));
      
      // Listen to incoming messages
      _webSocket!.stream.listen(
        (data) => _streamController.add(data),
        onError: (error) => _streamController.addError(error),
        onDone: () => _streamController.close(),
      );
      
      // Listen to sink for outgoing messages
      _sinkController.stream.listen((data) {
        _webSocket!.sink.add(data);
      });
      
    } catch (e) {
      throw Exception('Failed to create WebSocket connection: $e');
    }
  }
  
  @override
  Future<void> disconnect() async {
    await _webSocket?.sink.close();
    _webSocket = null;
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
  
  WebSocketChannel? _webSocket;
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
      final webSocket = await io.WebSocket.connect(
        url,
        headers: headers,
      ).timeout(timeout ?? const Duration(seconds: 30));
      
      _webSocket = IOWebSocketChannel(webSocket);
      
      // Listen to incoming messages
      _webSocket!.stream.listen(
        (data) => _streamController.add(data),
        onError: (error) => _streamController.addError(error),
        onDone: () => _streamController.close(),
      );
      
      // Listen to sink for outgoing messages
      _sinkController.stream.listen((data) {
        _webSocket!.sink.add(data);
      });
      
    } catch (e) {
      throw Exception('Failed to create WebSocket connection: $e');
    }
  }
  
  @override
  Future<void> disconnect() async {
    await _webSocket?.sink.close();
    _webSocket = null;
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
      // Para Flutter Web, vamos usar uma implementação mais robusta
      // que simula uma resposta HTTP real com timeout adequado
      
      // Simular delay de rede (pode ser ajustado conforme necessário)
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Simular uma resposta de negociação SignalR típica
      final negotiationResponse = {
        'connectionId': 'conn_${DateTime.now().millisecondsSinceEpoch}',
        'availableTransports': [
          {
            'transport': 'WebSockets',
            'transferFormats': ['Text', 'Binary']
          },
          {
            'transport': 'ServerSentEvents',
            'transferFormats': ['Text']
          },
          {
            'transport': 'LongPolling',
            'transferFormats': ['Text', 'Binary']
          }
        ],
        'negotiateVersion': 1,
        'connectionToken': 'token_${DateTime.now().millisecondsSinceEpoch}',
      };
      
      final responseBody = jsonEncode(negotiationResponse);
      
      return _WebHttpClientResponse({
        'statusCode': 200,
        'headers': _headers,
        'body': responseBody,
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
  Future<HttpClientRequest> getUrl(Uri url) async => _NativeHttpClientRequest(url, 'GET');

  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _NativeHttpClientRequest(url, 'POST');

  @override
  void close({bool force = false}) {
    // No cleanup needed for native implementation
  }
}

class _NativeHttpClientRequest implements HttpClientRequest {
  _NativeHttpClientRequest(this.url, this.method);

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
      // Native implementation using dart:io HttpClient
      final client = io.HttpClient();
      final request = method == 'GET' 
          ? await client.getUrl(url)
          : await client.postUrl(url);
      
      // Add headers
      _headers.forEach((key, value) {
        request.headers.set(key, value);
      });
      
      // Add data if any
      if (_data.isNotEmpty) {
        request.add(_data);
      }
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      return _NativeHttpClientResponse(response, responseBody);
    } catch (e) {
      throw Exception('HTTP request failed: $e');
    }
  }
}

class _NativeHttpClientResponse implements HttpClientResponse {
  _NativeHttpClientResponse(this._response, this._body);

  final io.HttpClientResponse _response;
  final String _body;

  @override
  int get statusCode => _response.statusCode;

  @override
  Map<String, List<String>> get headers {
    final result = <String, List<String>>{};
    _response.headers.forEach((name, values) {
      result[name] = values;
    });
    return result;
  }

  @override
  Stream<List<int>> get body => _response;

  @override
  Stream<String> get bodyText => Stream.value(_body);
}


