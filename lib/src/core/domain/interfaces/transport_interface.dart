import 'dart:async';

/// Supported transport types for SignalR connections
enum TransportType {
  /// WebSocket transport - bidirectional, real-time communication
  webSocket,
  
  /// Server-Sent Events transport - server-to-client streaming
  serverSentEvents,
  
  /// Long Polling transport - fallback for older environments
  longPolling,
  
  /// Auto-select best available transport based on server capabilities
  auto,
}

/// Transfer format for message serialization
enum TransferFormat {
  /// Text format - JSON serialization
  text,
  
  /// Binary format - MessagePack serialization
  binary,
}

/// Transport interface for different connection methods to SignalR hubs
abstract class TransportInterface {
  /// Transport type identifier
  TransportType get type;
  
  /// Supported transfer formats for this transport
  List<TransferFormat> get supportedFormats;
  
  /// Establishes connection to the SignalR hub
  Future<void> connect({
    required String url,
    Map<String, String>? headers,
    TransferFormat format = TransferFormat.text,
  });
  
  /// Closes the connection gracefully
  Future<void> disconnect();
  
  /// Sends data through the transport
  Future<void> send(dynamic data);
  
  /// Stream of received data from the transport
  Stream<dynamic> get dataStream;
  
  /// Stream of connection state changes (connected/disconnected)
  Stream<bool> get connectionStateStream;
  
  /// Current connection state
  bool get isConnected;
  
  /// Current connection URL
  String? get url;
  
  /// Current connection headers
  Map<String, String> get headers;
}

/// Factory for creating transport instances based on type and configuration
abstract class TransportFactory {
  /// Creates a transport instance with the specified configuration
  TransportInterface create({
    required TransportType type,
    Map<String, String>? headers,
    Duration? timeout,
  });
  
  /// Gets available transports for a specific URL by negotiating with the server
  Future<List<TransportType>> getAvailableTransports(String url);
  
  /// Gets the best available transport for a URL based on server capabilities
  Future<TransportType> getBestTransport(String url);
}
