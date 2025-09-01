
import '../core/domain/interfaces/transport_interface.dart';
import '../core/logging/signalr_logger.dart';
import '../transport/websocket_transport.dart';
import '../transport/sse_transport.dart';
import '../transport/long_polling_transport.dart';



/// Builder para configurar transports SignalR
class TransportBuilder {
  TransportType _type = TransportType.webSocket;
  Duration _connectTimeout = const Duration(seconds: 30);
  final Map<String, String> _customHeaders = {};

  /// Define o tipo de transport
  TransportBuilder withType(TransportType type) {
    _type = type;
    return this;
  }

  /// Define o timeout de conexão
  TransportBuilder withConnectTimeout(Duration timeout) {
    _connectTimeout = timeout;
    return this;
  }



  /// Adiciona headers customizados
  TransportBuilder withCustomHeaders(Map<String, String> headers) {
    _customHeaders.addAll(headers);
    return this;
  }

  /// Constrói e retorna o transport configurado
  TransportInterface build() {
    // Criar logger padrão
    final logger = SignalRLogger();
    
    switch (_type) {
      case TransportType.webSocket:
        return WebSocketTransport(
          logger: logger,
          headers: _customHeaders,
          timeout: _connectTimeout,
        );
      
      case TransportType.serverSentEvents:
        return SSETransport(
          logger: logger,
          headers: _customHeaders,
          timeout: _connectTimeout,
        );
      
      case TransportType.longPolling:
        return LongPollingTransport(
          logger: logger,
          headers: _customHeaders,
          timeout: _connectTimeout,
        );
      case TransportType.auto:
        // Auto-detect best transport (WebSocket preferred)
        return WebSocketTransport(
          logger: logger,
          headers: _customHeaders,
          timeout: _connectTimeout,
        );
    }
  }

  /// Cria um transport WebSocket
  static TransportBuilder websocket() => TransportBuilder().withType(TransportType.webSocket);

  /// Cria um transport Server-Sent Events
  static TransportBuilder serverSentEvents() => TransportBuilder().withType(TransportType.serverSentEvents);

  /// Cria um transport Long Polling
  static TransportBuilder longPolling() => TransportBuilder().withType(TransportType.longPolling);
}
