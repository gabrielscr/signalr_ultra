/// Represents the current state of a SignalR connection
enum ConnectionState {
  /// Connection is disconnected
  disconnected,
  
  /// Connection is connecting
  connecting,
  
  /// Connection is connected
  connected,
  
  /// Connection is disconnecting
  disconnecting,
  
  /// Connection is reconnecting
  reconnecting,
  
  /// Connection failed
  failed,
}

/// Connection metadata with immutable properties
class ConnectionMetadata {

  const ConnectionMetadata({
    required this.connectionId,
    required this.baseUrl,
    required this.connectedAt,
    this.lastPingAt,
    this.messageCount = 0,
    this.errorCount = 0,
    required this.uptime,
    this.headers,
  });

  factory ConnectionMetadata.fromJson(Map<String, dynamic> json) => ConnectionMetadata(
      connectionId: json['connectionId'] as String,
      baseUrl: json['baseUrl'] as String,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
      lastPingAt: json['lastPingAt'] != null 
          ? DateTime.parse(json['lastPingAt'] as String)
          : null,
      messageCount: json['messageCount'] as int? ?? 0,
      errorCount: json['errorCount'] as int? ?? 0,
      uptime: Duration(milliseconds: json['uptime'] as int),
      headers: json['headers'] != null 
          ? Map<String, String>.from(json['headers'] as Map)
          : null,
    );
  final String connectionId;
  final String baseUrl;
  final DateTime connectedAt;
  final DateTime? lastPingAt;
  final int messageCount;
  final int errorCount;
  final Duration uptime;
  final Map<String, String>? headers;

  Map<String, dynamic> toJson() => {
      'connectionId': connectionId,
      'baseUrl': baseUrl,
      'connectedAt': connectedAt.toIso8601String(),
      'lastPingAt': lastPingAt?.toIso8601String(),
      'messageCount': messageCount,
      'errorCount': errorCount,
      'uptime': uptime.inMilliseconds,
      'headers': headers,
    };

  ConnectionMetadata copyWith({
    String? connectionId,
    String? baseUrl,
    DateTime? connectedAt,
    DateTime? lastPingAt,
    int? messageCount,
    int? errorCount,
    Duration? uptime,
    Map<String, String>? headers,
  }) => ConnectionMetadata(
      connectionId: connectionId ?? this.connectionId,
      baseUrl: baseUrl ?? this.baseUrl,
      connectedAt: connectedAt ?? this.connectedAt,
      lastPingAt: lastPingAt ?? this.lastPingAt,
      messageCount: messageCount ?? this.messageCount,
      errorCount: errorCount ?? this.errorCount,
      uptime: uptime ?? this.uptime,
      headers: headers ?? this.headers,
    );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionMetadata &&
          runtimeType == other.runtimeType &&
          connectionId == other.connectionId &&
          baseUrl == other.baseUrl;

  @override
  int get hashCode => connectionId.hashCode ^ baseUrl.hashCode;

  @override
  String toString() => 'ConnectionMetadata(connectionId: $connectionId, baseUrl: $baseUrl, uptime: $uptime)';
}
