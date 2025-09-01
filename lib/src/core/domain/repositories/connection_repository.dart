import 'dart:async';

import '../entities/connection_state.dart';

/// Repository interface for managing SignalR connections
abstract class ConnectionRepository {
  /// Establishes a connection to the SignalR hub
  Future<ConnectionMetadata> connect({
    required String url,
    Map<String, String>? headers,
    Duration? timeout,
  });

  /// Disconnects from the SignalR hub
  Future<void> disconnect();

  /// Sends a message to the hub
  Future<void> sendMessage({
    required String method,
    List<dynamic>? arguments,
    Map<String, String>? headers,
  });

  /// Invokes a hub method and waits for response
  Future<T> invoke<T>({
    required String method,
    List<dynamic>? arguments,
    Map<String, String>? headers,
    Duration? timeout,
  });

  /// Streams messages from the hub
  Stream<dynamic> stream({
    required String method,
    List<dynamic>? arguments,
    Map<String, String>? headers,
  });

  /// Listens to hub method invocations
  void on(String method, Function(List<dynamic> arguments) handler);

  /// Removes a method listener
  void off(String method);

  /// Gets the current connection state
  ConnectionState get state;

  /// Stream of connection state changes
  Stream<ConnectionState> get stateStream;

  /// Gets connection metadata
  ConnectionMetadata? get metadata;

  /// Stream of connection metadata updates
  Stream<ConnectionMetadata> get metadataStream;

  /// Checks if connection is active
  bool get isConnected;

  /// Gets connection statistics
  Map<String, dynamic> get statistics;
}
