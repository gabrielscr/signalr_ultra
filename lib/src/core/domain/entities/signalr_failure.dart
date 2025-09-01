import 'package:dartz/dartz.dart';

import '../../../../signalr_ultra.dart';

/// Base class for SignalR failures
abstract class SignalRFailure {

  const SignalRFailure(this.message, {this.code, this.context});
  final String message;
  final String? code;
  final Map<String, dynamic>? context;

  @override
  String toString() => 'SignalRFailure: $message';
}

/// Connection failures
class ConnectionFailure extends SignalRFailure {
  const ConnectionFailure(String message, {String? code, Map<String, dynamic>? context})
      : super(message, code: code, context: context);
}

/// Transport failures
class TransportFailure extends SignalRFailure {
  const TransportFailure(String message, {String? code, Map<String, dynamic>? context})
      : super(message, code: code, context: context);
}

/// Protocol failures
class ProtocolFailure extends SignalRFailure {
  const ProtocolFailure(String message, {String? code, Map<String, dynamic>? context})
      : super(message, code: code, context: context);
}

/// Authentication failures
class AuthenticationFailure extends SignalRFailure {
  const AuthenticationFailure(String message, {String? code, Map<String, dynamic>? context})
      : super(message, code: code, context: context);
}

/// Timeout failures
class TimeoutFailure extends SignalRFailure {
  const TimeoutFailure(String message, {String? code, Map<String, dynamic>? context})
      : super(message, code: code, context: context);
}

/// Network failures
class NetworkFailure extends SignalRFailure {
  const NetworkFailure(String message, {String? code, Map<String, dynamic>? context})
      : super(message, code: code, context: context);
}

/// Serialization failures
class SerializationFailure extends SignalRFailure {
  const SerializationFailure(String message, {String? code, Map<String, dynamic>? context})
      : super(message, code: code, context: context);
}

/// Type alias for Either with SignalR failures
typedef SignalREither<T> = Either<SignalRFailure, T>;

/// Type alias for Either with connection result
typedef ConnectionResult = SignalREither<ConnectionMetadata>;

/// Type alias for Either with invocation result
typedef InvocationResult<T> = SignalREither<T>;

/// Utility functions for working with SignalR failures
class SignalRFailureUtils {
  /// Creates a connection failure
  static ConnectionFailure connectionFailure(String message, {String? code, Map<String, dynamic>? context}) => ConnectionFailure(message, code: code, context: context);

  /// Creates a transport failure
  static TransportFailure transportFailure(String message, {String? code, Map<String, dynamic>? context}) => TransportFailure(message, code: code, context: context);

  /// Creates a protocol failure
  static ProtocolFailure protocolFailure(String message, {String? code, Map<String, dynamic>? context}) => ProtocolFailure(message, code: code, context: context);

  /// Creates an authentication failure
  static AuthenticationFailure authenticationFailure(String message, {String? code, Map<String, dynamic>? context}) => AuthenticationFailure(message, code: code, context: context);

  /// Creates a timeout failure
  static TimeoutFailure timeoutFailure(String message, {String? code, Map<String, dynamic>? context}) => TimeoutFailure(message, code: code, context: context);

  /// Creates a network failure
  static NetworkFailure networkFailure(String message, {String? code, Map<String, dynamic>? context}) => NetworkFailure(message, code: code, context: context);

  /// Creates a serialization failure
  static SerializationFailure serializationFailure(String message, {String? code, Map<String, dynamic>? context}) => SerializationFailure(message, code: code, context: context);

  /// Checks if failure is retryable
  static bool isRetryable(SignalRFailure failure) => failure is NetworkFailure ||
        failure is TimeoutFailure ||
        (failure is ConnectionFailure && failure.code != 'AUTH_FAILED');

  /// Gets failure severity level
  static int getSeverity(SignalRFailure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 1;
      case TimeoutFailure:
        return 2;
      case ConnectionFailure:
        return 3;
      case TransportFailure:
        return 4;
      case ProtocolFailure:
        return 5;
      case AuthenticationFailure:
        return 6;
      case SerializationFailure:
        return 7;
      default:
        return 0;
    }
  }
}
