import 'dart:convert';
import 'dart:typed_data';

import '../core/domain/interfaces/retry_interface.dart';
import '../core/domain/interfaces/transport_interface.dart';
import '../core/domain/interfaces/protocol_interface.dart';
import '../core/domain/interfaces/observability_interface.dart';
import '../core/logging/signalr_logger.dart';
import '../transport/websocket_transport.dart';
import '../transport/sse_transport.dart';
import '../transport/long_polling_transport.dart';
import '../signalr_client.dart';

/// Builder for configuring the SignalR Ultra client
class SignalRBuilder {
  SignalRBuilder();

  String? _url;
  final Map<String, String> _headers = {};
  TransportType _transportType = TransportType.auto;
  Duration _timeout = const Duration(seconds: 30);
  
  // Logging configuration
  Level _logLevel = Level.info;
  String? _logPrefix;
  
  // Circuit breaker configuration
  int _failureThreshold = 5;
  Duration _resetTimeout = const Duration(minutes: 1);

  /// Sets the SignalR hub URL
  SignalRBuilder withUrl(String url) {
    _url = url;
    return this;
  }

  /// Sets custom headers for the connection
  SignalRBuilder withHeaders(Map<String, String> headers) {
    _headers.addAll(headers);
    return this;
  }

  /// Sets the transport type
  SignalRBuilder withTransport(TransportType transportType) {
    _transportType = transportType;
    return this;
  }

  /// Sets connection timeout
  SignalRBuilder withTimeout(Duration timeout) {
    _timeout = timeout;
    return this;
  }

  /// Sets log level
  SignalRBuilder withLogLevel(Level level) {
    _logLevel = level;
    return this;
  }

  /// Sets log prefix
  SignalRBuilder withLogPrefix(String prefix) {
    _logPrefix = prefix;
    return this;
  }

  /// Sets failure threshold for circuit breaker
  SignalRBuilder withFailureThreshold(int threshold) {
    _failureThreshold = threshold;
    return this;
  }

  /// Sets reset timeout for circuit breaker
  SignalRBuilder withResetTimeout(Duration timeout) {
    _resetTimeout = timeout;
    return this;
  }

  /// Builds the SignalR client
  SignalRClient build() {
    if (_url == null) {
      throw ArgumentError('URL must be provided using withUrl()');
    }

    final logger = SignalRLogger(
      level: _logLevel,
      prefix: _logPrefix,
    );

    final circuitBreaker = SimpleCircuitBreaker(
      failureThreshold: _failureThreshold,
      resetTimeout: _resetTimeout,
    );

    final observability = SimpleObservability();

    final transport = _createTransport(logger);

    final protocol = JsonProtocol();

    final client = SignalRClient(
      transport: transport,
      protocol: protocol,
      circuitBreaker: circuitBreaker,
      observability: observability,
    );
    
    return client;
  }

  TransportInterface _createTransport(SignalRLogger logger) {
    switch (_transportType) {
      case TransportType.webSocket:
        return WebSocketTransport(
          logger: logger,
          headers: _headers,
          timeout: _timeout,
        );
      case TransportType.serverSentEvents:
        return SSETransport(
          logger: logger,
          headers: _headers,
          timeout: _timeout,
        );
      case TransportType.auto:
        // Auto-detect best transport (WebSocket preferred)
        return WebSocketTransport(
          logger: logger,
          headers: _headers,
          timeout: _timeout,
        );
      case TransportType.longPolling:
        return LongPollingTransport(
          logger: logger,
          headers: _headers,
          timeout: _timeout,
        );
    }
  }
}

/// Simple JSON protocol implementation for SignalR
class JsonProtocol implements ProtocolInterface {
  @override
  String get name => 'json';

  @override
  int get version => 1;

  @override
  TransferFormat get transferFormat => TransferFormat.text;

  @override
  Uint8List writeMessage(SignalRMessage message) {
    final jsonMap = _messageToJson(message);
    final jsonString = jsonEncode(jsonMap);
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  @override
  List<SignalRMessage> parseMessages(Uint8List data) {
    try {
      final json = utf8.decode(data);
      
      // Verificar se é uma mensagem única ou múltiplas mensagens
      if (json.startsWith('[') && json.endsWith(']')) {
        // Múltiplas mensagens em array
        final List<dynamic> messages = jsonDecode(json);
        return messages.map((msg) => _jsonToMessage(jsonEncode(msg))).toList();
      } else {
        // Mensagem única
        return [_jsonToMessage(json)];
      }
    } catch (e) {
      // Se falhar ao fazer parse, retornar lista vazia
      return [];
    }
  }

  @override
  Uint8List createHandshakeRequest() {
    final handshake = {
      'protocol': name,
      'version': version,
    };
    final jsonString = jsonEncode(handshake);
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  @override
  bool parseHandshakeResponse(Uint8List data) {
    try {
      final json = utf8.decode(data);
      final response = jsonDecode(json);
      
      // SignalR pode retornar diferentes formatos de resposta
      if (response is Map<String, dynamic>) {
        // Verificar se há erro
        if (response.containsKey('error')) {
          final error = response['error'];
          if (error != null && error.toString().isNotEmpty) {
            return false;
          }
        }
        
        // Verificar se há connectionId (resposta bem-sucedida)
        if (response.containsKey('connectionId')) {
          return true;
        }
        
        // Verificar se há negotiateVersion (resposta de negociação)
        if (response.containsKey('negotiateVersion')) {
          return true;
        }
        
        // Verificar se há availableTransports (resposta de negociação)
        if (response.containsKey('availableTransports')) {
          return true;
        }
        
        // Se não há erro e tem outros campos, considerar como sucesso
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  bool isValidMessage(Uint8List data) {
    try {
      final json = utf8.decode(data);
      jsonDecode(json);
      return true;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> _messageToJson(SignalRMessage message) {
    if (message is InvocationMessage) {
      return {
        'type': message.type.value,
        'target': message.target,
        'arguments': message.arguments,
        'invocationId': message.invocationId,
        'streamIds': message.streamIds,
        'headers': message.headers,
      };
    } else if (message is CompletionMessage) {
      return {
        'type': message.type.value,
        'invocationId': message.invocationId,
        'result': message.result,
        'error': message.error,
        'headers': message.headers,
      };
    }
    
    return {
      'type': message.type.value,
      'headers': message.headers,
    };
  }

  SignalRMessage _jsonToMessage(String json) {
    try {
      final data = jsonDecode(json);
      
      // Verificar se é um mapa válido
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid message format: expected Map, got ${data.runtimeType}');
      }
      
      final type = data['type'];
      if (type == null) {
        throw Exception('Message type is required');
      }
      
      final messageType = type is int ? type : int.tryParse(type.toString());
      if (messageType == null) {
        throw Exception('Invalid message type: $type');
      }
      
      switch (messageType) {
        case 1: // Invocation
          return InvocationMessage(
            target: data['target'] as String? ?? '',
            arguments: data['arguments'] as List<dynamic>?,
            invocationId: data['invocationId'] as String?,
            streamIds: (data['streamIds'] as List<dynamic>?)?.cast<String>(),
            headers: (data['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
          );
        case 3: // Completion
          return CompletionMessage(
            invocationId: data['invocationId'] as String?,
            result: data['result'],
            error: data['error'] as String?,
            headers: (data['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
          );
        case 6: // Ping
          return CompletionMessage(
            invocationId: null,
            result: null,
            error: null,
            headers: null,
          );
        default:
          // Para tipos desconhecidos, criar uma mensagem genérica
          return CompletionMessage(
            invocationId: data['invocationId'] as String?,
            result: data['result'],
            error: data['error'] as String?,
            headers: (data['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
          );
      }
    } catch (e) {
      throw Exception('Failed to parse message: $e');
    }
  }
}
