import 'dart:developer' as developer;

// Constante para substituir kDebugMode
const bool _kDebugMode = true;

/// Sistema de logging próprio para SignalR Ultra
class SignalRLogger {
  SignalRLogger({
    Level level = Level.info,
    String? prefix,
  }) : _appLevel = level,
       _prefix = prefix ?? 'SIGNALR';

  final Level _appLevel;
  final String _prefix;

  void verbose(
    String message, {
    String? name,
    StackTrace? stackTrace,
    Object? exception,
    Map<String, dynamic>? context,
  }) {
    const level = Level.verbose;
    final show = _appLevel.index <= level.index;
    if (show) {
      return developer.log(
        _formatMessage(Level.verbose, message, context),
        name: '$_prefix: $name',
        error: exception,
        stackTrace: stackTrace,
      );
    }
  }

  void debug(
    String message, {
    String name = 'DEBUG',
    StackTrace? stackTrace,
    Object? exception,
    Map<String, dynamic>? context,
  }) {
    const level = Level.debug;
    final show = _appLevel.index <= level.index;

    if (_kDebugMode && show) {
      return developer.log(
        _formatMessage(Level.debug, message, context),
        name: '$_prefix: $name',
        error: exception,
        stackTrace: stackTrace,
      );
    }
  }

  void info(
    String message, {
    String name = 'INFO',
    StackTrace? stackTrace,
    Object? exception,
    Map<String, dynamic>? context,
  }) {
    const level = Level.info;
    final show = _appLevel.index <= level.index;

    if (_kDebugMode && show) {
      try {
        return developer.log(
          _formatMessage(Level.info, message, context),
          name: '$_prefix: $name',
          error: exception,
          stackTrace: stackTrace,
        );
      } catch (e) {
        // Fallback para evitar erros de debug
      }
    }
  }

  void warning(
    String message, {
    String name = 'WARNING',
    StackTrace? stackTrace,
    Object? exception,
    Map<String, dynamic>? context,
  }) {
    const level = Level.warning;
    final show = _appLevel.index <= level.index;

    if (_kDebugMode && show) {
      try {
        return developer.log(
          _formatMessage(Level.warning, message, context),
          name: '$_prefix: $name',
          error: exception,
          stackTrace: stackTrace,
        );
      } catch (e) {
        // Fallback para evitar erros de debug
      }
    }
  }

  void error(
    String message, {
    String name = 'ERROR',
    StackTrace? stackTrace,
    Object? exception,
    Map<String, dynamic>? context,
  }) {
    const level = Level.error;
    final show = _appLevel.index <= level.index;
    if (_kDebugMode && show) {
      try {
        return developer.log(
          _formatMessage(Level.error, message, context),
          name: '$_prefix: $name',
          error: exception,
          stackTrace: stackTrace,
        );
      } catch (e) {
        // Fallback para evitar erros de debug
      }
    }
  }

  /// Log para operações de conexão
  void connection(
    String message, {
    String operation = 'CONNECT',
    String url = '',
    String connectionId = '',
    Map<String, dynamic>? data,
    String name = 'CONNECTION',
  }) {
    final connMessage = _formatConnectionMessage(operation, url, connectionId, data, message);
    info(connMessage, name: name);
  }

  /// Log para operações de transporte
  void transport(
    String message, {
    String type = 'WEBSOCKET',
    String operation = 'SEND',
    Map<String, dynamic>? data,
    String name = 'TRANSPORT',
  }) {
    final transportMessage = _formatTransportMessage(type, operation, data, message);
    debug(transportMessage, name: name);
  }

  /// Log para operações de protocolo
  void protocol(
    String message, {
    String operation = 'SERIALIZE',
    String messageType = '',
    Map<String, dynamic>? data,
    String name = 'PROTOCOL',
  }) {
    final protocolMessage = _formatProtocolMessage(operation, messageType, data, message);
    debug(protocolMessage, name: name);
  }

  /// Log para operações de retry/circuit breaker
  void resilience(
    String message, {
    String operation = 'RETRY',
    int attempt = 0,
    String state = '',
    Map<String, dynamic>? data,
    String name = 'RESILIENCE',
  }) {
    final resilienceMessage = _formatResilienceMessage(operation, attempt, state, data, message);
    info(resilienceMessage, name: name);
  }

  /// Log para operações de métricas
  void metrics(
    String message, {
    String metric = 'COUNTER',
    String name = 'METRICS',
    Map<String, dynamic>? data,
  }) {
    final metricsMessage = _formatMetricsMessage(metric, data, message);
    debug(metricsMessage, name: name);
  }

  String _formatMessage(
    Level level,
    String message,
    Map<String, dynamic>? context,
  ) {
    final emoji = _levelEmojis[level];
    final color = _levelColors[level];
    final time = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' | Context: $context' : '';

    return '$time $color$emoji$message$contextStr$_reset';
  }

  String _formatConnectionMessage(
    String operation,
    String url,
    String connectionId,
    Map<String, dynamic>? data,
    String message,
  ) {
    final urlInfo = url.isNotEmpty ? ' to $url' : '';
    final connInfo = connectionId.isNotEmpty ? ' [$connectionId]' : '';
    final dataInfo = data != null ? ' | Data: $data' : '';
    return '$operation$urlInfo$connInfo$dataInfo | $message';
  }

  String _formatTransportMessage(
    String type,
    String operation,
    Map<String, dynamic>? data,
    String message,
  ) {
    final dataInfo = data != null ? ' | Data: $data' : '';
    return '$type $operation$dataInfo | $message';
  }

  String _formatProtocolMessage(
    String operation,
    String messageType,
    Map<String, dynamic>? data,
    String message,
  ) {
    final typeInfo = messageType.isNotEmpty ? ' $messageType' : '';
    final dataInfo = data != null ? ' | Data: $data' : '';
    return '$operation$typeInfo$dataInfo | $message';
  }

  String _formatResilienceMessage(
    String operation,
    int attempt,
    String state,
    Map<String, dynamic>? data,
    String message,
  ) {
    final attemptInfo = attempt > 0 ? ' (attempt $attempt)' : '';
    final stateInfo = state.isNotEmpty ? ' [$state]' : '';
    final dataInfo = data != null ? ' | Data: $data' : '';
    return '$operation$attemptInfo$stateInfo$dataInfo | $message';
  }

  String _formatMetricsMessage(
    String metric,
    Map<String, dynamic>? data,
    String message,
  ) {
    final dataInfo = data != null ? ' | Data: $data' : '';
    return '$metric$dataInfo | $message';
  }
}

/// Níveis de log
enum Level {
  verbose,
  debug,
  info,
  warning,
  error,
}

/// Extension para métodos do enum Level
extension LevelExtension on Level {
  static Level fromString(String level) {
    switch (level.toUpperCase()) {
      case 'VERBOSE':
        return Level.verbose;
      case 'DEBUG':
        return Level.debug;
      case 'INFO':
        return Level.info;
      case 'WARNING':
        return Level.warning;
      case 'ERROR':
        return Level.error;
      default:
        return Level.info;
    }
  }
}

const _levelEmojis = {
  Level.verbose: '🔍 ',
  Level.debug: '🐛 ',
  Level.info: '💡 ',
  Level.warning: '🟨 ',
  Level.error: '⛔ ',
};

const _levelColors = {
  Level.verbose: _white,
  Level.info: _green,
  Level.debug: _blue,
  Level.warning: _yellow,
  Level.error: _red,
};

/// Códigos ANSI para cores
const _reset = '\x1B[0m';
const _white = '\x1B[37m';
const _red = '\x1B[31m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _blue = '\x1B[34m';
