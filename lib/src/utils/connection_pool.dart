import 'dart:async';
import 'dart:collection';

import '../signalr_client.dart';

/// Pool de conexões SignalR para gerenciar múltiplas conexões
class ConnectionPool {

  ConnectionPool({
    int maxConnections = 10,
    Duration idleTimeout = const Duration(minutes: 5),
  }) : _maxConnections = maxConnections,
       _idleTimeout = idleTimeout {
    _startIdleCleanup();
  }
  final int _maxConnections;
  final Duration _idleTimeout;
  
  final Map<String, SignalRClient> _activeConnections = {};
  final Queue<SignalRClient> _idleConnections = Queue<SignalRClient>();
  final Map<String, DateTime> _lastUsed = {};
  
  final StreamController<ConnectionPoolEvent> _eventController = 
      StreamController<ConnectionPoolEvent>.broadcast();

  /// Stream de eventos do pool
  Stream<ConnectionPoolEvent> get events => _eventController.stream;

  /// Número de conexões ativas
  int get activeConnections => _activeConnections.length;

  /// Número de conexões ociosas
  int get idleConnections => _idleConnections.length;

  /// Número total de conexões
  int get totalConnections => activeConnections + idleConnections;

  /// Obtém uma conexão do pool
  Future<SignalRClient> getConnection({
    required String url,
    Map<String, String>? headers,
  }) async {
    final key = _generateConnectionKey(url, headers);
    
    // Verificar se já existe uma conexão ativa
    if (_activeConnections.containsKey(key)) {
      final connection = _activeConnections[key]!;
      _lastUsed[key] = DateTime.now();
      return connection;
    }

    // Verificar se há uma conexão ociosa disponível
    if (_idleConnections.isNotEmpty) {
      final connection = _idleConnections.removeFirst();
      _activeConnections[key] = connection;
      _lastUsed[key] = DateTime.now();
      
      _eventController.add(ConnectionPoolEvent.connectionReused(key));
      return connection;
    }

    // Verificar se podemos criar uma nova conexão
    if (totalConnections >= _maxConnections) {
      throw Exception('Pool de conexões cheio. Máximo: $_maxConnections');
    }

    // Criar nova conexão
    final connection = await _createConnection(url, headers);
    _activeConnections[key] = connection;
    _lastUsed[key] = DateTime.now();
    
    _eventController.add(ConnectionPoolEvent.connectionCreated(key));
    return connection;
  }

  /// Libera uma conexão de volta para o pool
  void releaseConnection(String url, Map<String, String>? headers) {
    final key = _generateConnectionKey(url, headers);
    final connection = _activeConnections.remove(key);
    
    if (connection != null) {
      _idleConnections.add(connection);
      _eventController.add(ConnectionPoolEvent.connectionReleased(key));
    }
  }

  /// Fecha uma conexão específica
  Future<void> closeConnection(String url, Map<String, String>? headers) async {
    final key = _generateConnectionKey(url, headers);
    final connection = _activeConnections.remove(key);
    
    if (connection != null) {
      await connection.disconnect();
      _eventController.add(ConnectionPoolEvent.connectionClosed(key));
    }
  }

  /// Fecha todas as conexões do pool
  Future<void> closeAll() async {
    final futures = <Future<void>>[];
    
    // Fechar conexões ativas
    for (final connection in _activeConnections.values) {
      futures.add(connection.disconnect());
    }
    _activeConnections.clear();
    
    // Fechar conexões ociosas
    for (final connection in _idleConnections) {
      futures.add(connection.disconnect());
    }
    _idleConnections.clear();
    
    await Future.wait(futures);
    _eventController.add(ConnectionPoolEvent.allConnectionsClosed());
  }

  /// Gera uma chave única para a conexão
  String _generateConnectionKey(String url, Map<String, String>? headers) {
    final headerString = headers?.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',') ?? '';
    return '$url|$headerString';
  }

  /// Cria uma nova conexão
  Future<SignalRClient> _createConnection(
    String url, 
    Map<String, String>? headers,
  ) async {
    // Implementação básica - será expandida posteriormente
    throw UnimplementedError('Criação de conexão ainda não implementada');
  }

  /// Inicia a limpeza de conexões ociosas
  void _startIdleCleanup() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _cleanupIdleConnections();
    });
  }

  /// Remove conexões ociosas que excederam o timeout
  void _cleanupIdleConnections() {
    final now = DateTime.now();
    final toRemove = <String>[];
    
    for (final entry in _lastUsed.entries) {
      if (now.difference(entry.value) > _idleTimeout) {
        toRemove.add(entry.key);
      }
    }
    
    for (final key in toRemove) {
      final connection = _activeConnections.remove(key);
      if (connection != null) {
        connection.disconnect();
        _eventController.add(ConnectionPoolEvent.connectionTimedOut(key));
      }
      _lastUsed.remove(key);
    }
  }

  /// Dispose do pool
  void dispose() {
    closeAll();
    _eventController.close();
  }
}

/// Eventos do pool de conexões
enum ConnectionPoolEventType {
  connectionCreated,
  connectionReused,
  connectionReleased,
  connectionClosed,
  connectionTimedOut,
  allConnectionsClosed,
}

/// Evento do pool de conexões
class ConnectionPoolEvent {

  ConnectionPoolEvent._({
    required this.type,
    this.connectionKey,
    required this.timestamp,
  });

  factory ConnectionPoolEvent.connectionCreated(String key) => ConnectionPoolEvent._(
      type: ConnectionPoolEventType.connectionCreated,
      connectionKey: key,
      timestamp: DateTime.now(),
    );

  factory ConnectionPoolEvent.connectionReused(String key) => ConnectionPoolEvent._(
      type: ConnectionPoolEventType.connectionReused,
      connectionKey: key,
      timestamp: DateTime.now(),
    );

  factory ConnectionPoolEvent.connectionReleased(String key) => ConnectionPoolEvent._(
      type: ConnectionPoolEventType.connectionReleased,
      connectionKey: key,
      timestamp: DateTime.now(),
    );

  factory ConnectionPoolEvent.connectionClosed(String key) => ConnectionPoolEvent._(
      type: ConnectionPoolEventType.connectionClosed,
      connectionKey: key,
      timestamp: DateTime.now(),
    );

  factory ConnectionPoolEvent.connectionTimedOut(String key) => ConnectionPoolEvent._(
      type: ConnectionPoolEventType.connectionTimedOut,
      connectionKey: key,
      timestamp: DateTime.now(),
    );

  factory ConnectionPoolEvent.allConnectionsClosed() => ConnectionPoolEvent._(
      type: ConnectionPoolEventType.allConnectionsClosed,
      timestamp: DateTime.now(),
    );
  final ConnectionPoolEventType type;
  final String? connectionKey;
  final DateTime timestamp;
}
