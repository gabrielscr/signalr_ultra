import 'dart:typed_data';
import 'transport_interface.dart';

/// SignalR message types
enum MessageType {
  /// Invocation message
  invocation,
  
  /// Stream item message
  streamItem,
  
  /// Completion message
  completion,
  
  /// Stream invocation message
  streamInvocation,
  
  /// Cancel invocation message
  cancelInvocation,
  
  /// Ping message
  ping,
  
  /// Close message
  close,
  
  /// Ack message
  ack,
  
  /// Sequence message
  sequence,
  
  /// Handshake request
  handshakeRequest,
  
  /// Handshake response
  handshakeResponse,
  
  /// Handshake error
  handshakeError,
}

/// Extension to get message type values
extension MessageTypeExtension on MessageType {
  int get value {
    switch (this) {
      case MessageType.invocation:
        return 1;
      case MessageType.streamItem:
        return 2;
      case MessageType.completion:
        return 3;
      case MessageType.streamInvocation:
        return 4;
      case MessageType.cancelInvocation:
        return 5;
      case MessageType.ping:
        return 6;
      case MessageType.close:
        return 7;
      case MessageType.ack:
        return 8;
      case MessageType.sequence:
        return 9;
      case MessageType.handshakeRequest:
        return 10;
      case MessageType.handshakeResponse:
        return 11;
      case MessageType.handshakeError:
        return 12;
    }
  }
}

/// Base message class
abstract class SignalRMessage {
  /// Message type
  MessageType get type;
  
  /// Message headers
  Map<String, String>? get headers;
  
  /// Serializes message to bytes
  Uint8List serialize();
  
  /// Creates message from bytes
  static SignalRMessage deserialize(Uint8List data) {
    throw UnimplementedError('Subclasses must implement deserialize');
  }
}

/// Invocation message
class InvocationMessage extends SignalRMessage {

  InvocationMessage({
    required this.target,
    this.arguments,
    this.invocationId,
    this.streamIds,
    this.headers,
  });
  final String target;
  final List<dynamic>? arguments;
  final String? invocationId;
  final List<String>? streamIds;
  final Map<String, String>? headers;

  @override
  MessageType get type => MessageType.invocation;

  @override
  Uint8List serialize() {
    // Implementation will be in concrete protocol classes
    throw UnimplementedError();
  }
}

/// Completion message
class CompletionMessage extends SignalRMessage {

  CompletionMessage({
    this.invocationId,
    this.result,
    this.error,
    this.headers,
  });
  final String? invocationId;
  final dynamic result;
  final String? error;
  final Map<String, String>? headers;

  @override
  MessageType get type => MessageType.completion;

  @override
  Uint8List serialize() {
    // Implementation will be in concrete protocol classes
    throw UnimplementedError();
  }
}

/// Protocol interface for message serialization
abstract class ProtocolInterface {
  /// Protocol name
  String get name;
  
  /// Protocol version
  int get version;
  
  /// Transfer format
  TransferFormat get transferFormat;
  
  /// Serializes message to bytes
  Uint8List writeMessage(SignalRMessage message);
  
  /// Deserializes message from bytes
  List<SignalRMessage> parseMessages(Uint8List data);
  
  /// Creates handshake request
  Uint8List createHandshakeRequest();
  
  /// Parses handshake response
  bool parseHandshakeResponse(Uint8List data);
  
  /// Validates message format
  bool isValidMessage(Uint8List data);
}
