import 'dart:async';

import '../core/domain/interfaces/transport_interface.dart';
import '../core/domain/interfaces/protocol_interface.dart';
import '../core/domain/interfaces/retry_interface.dart';
import '../core/domain/interfaces/observability_interface.dart';
import '../signalr_client.dart';

/// Builder para configurar conexões SignalR com opções avançadas
class ConnectionBuilder {
  String? _url;
  final Map<String, String> _headers = {};
  Duration _timeout = const Duration(seconds: 30);

  TransportInterface? _transport;
  ProtocolInterface? _protocol;
  CircuitBreaker? _circuitBreaker;
  ObservabilityInterface? _observability;

  /// Define a URL do hub SignalR
  ConnectionBuilder withUrl(String url) {
    _url = url;
    return this;
  }

  /// Adiciona headers customizados
  ConnectionBuilder withHeaders(Map<String, String> headers) {
    _headers.addAll(headers);
    return this;
  }

  /// Define o timeout de conexão
  ConnectionBuilder withTimeout(Duration timeout) {
    _timeout = timeout;
    return this;
  }

  /// Define o transport customizado
  ConnectionBuilder withTransport(TransportInterface transport) {
    _transport = transport;
    return this;
  }

  /// Define o protocolo customizado
  ConnectionBuilder withProtocol(ProtocolInterface protocol) {
    _protocol = protocol;
    return this;
  }

  /// Define o circuit breaker customizado
  ConnectionBuilder withCircuitBreaker(CircuitBreaker circuitBreaker) {
    _circuitBreaker = circuitBreaker;
    return this;
  }

  /// Define a interface de observabilidade customizada
  ConnectionBuilder withObservability(ObservabilityInterface observability) {
    _observability = observability;
    return this;
  }

  /// Constrói e retorna o cliente SignalR configurado
  SignalRClient build() {
    if (_url == null) {
      throw ArgumentError('URL é obrigatória. Use withUrl() para definir.');
    }

    // Usar implementações padrão se não fornecidas
    final transport = _transport ?? _createDefaultTransport();
    final protocol = _protocol ?? _createDefaultProtocol();
    final circuitBreaker = _circuitBreaker ?? _createDefaultCircuitBreaker();
    final observability = _observability ?? _createDefaultObservability();

    return SignalRClient(
      transport: transport,
      protocol: protocol,
      circuitBreaker: circuitBreaker,
      observability: observability,
    );
  }

  /// Conecta e retorna o cliente configurado
  Future<SignalRClient> connect() async {
    final client = build();
    await client.connect(
      url: _url!,
      headers: _headers,
      timeout: _timeout,
    );
    return client;
  }

  // Métodos privados para criar implementações padrão
  TransportInterface _createDefaultTransport() {
    // Implementação padrão - será criada posteriormente
    throw UnimplementedError('Transport padrão ainda não implementado');
  }

  ProtocolInterface _createDefaultProtocol() {
    // Implementação padrão - será criada posteriormente
    throw UnimplementedError('Protocolo padrão ainda não implementado');
  }

  CircuitBreaker _createDefaultCircuitBreaker() {
    // Implementação padrão - será criada posteriormente
    throw UnimplementedError('Circuit breaker padrão ainda não implementado');
  }

  ObservabilityInterface _createDefaultObservability() {
    // Implementação padrão - será criada posteriormente
    throw UnimplementedError('Observabilidade padrão ainda não implementado');
  }
}
