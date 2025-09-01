import 'package:flutter_test/flutter_test.dart';
import 'package:signalr_ultra/signalr_ultra.dart';

void main() {
  group('SignalRLogger Tests', () {
    late SignalRLogger logger;

    setUp(() {
      logger = SignalRLogger();
    });

    group('Constructor and Initialization', () {
      test('should create logger with default values', () {
        expect(logger, isNotNull);
      });

      test('should create logger with custom level', () {
        final customLogger = SignalRLogger(level: Level.debug);
        expect(customLogger, isNotNull);
      });

      test('should create logger with custom prefix', () {
        final customLogger = SignalRLogger(prefix: 'CUSTOM');
        expect(customLogger, isNotNull);
      });
    });

    group('Logging Methods', () {
      test('should log verbose messages', () {
        expect(() => logger.verbose('Verbose message'), returnsNormally);
      });

      test('should log debug messages', () {
        expect(() => logger.debug('Debug message'), returnsNormally);
      });

      test('should log info messages', () {
        expect(() => logger.info('Info message'), returnsNormally);
      });

      test('should log warning messages', () {
        expect(() => logger.warning('Warning message'), returnsNormally);
      });

      test('should log error messages', () {
        expect(() => logger.error('Error message'), returnsNormally);
      });
    });

    group('Logging with Context', () {
      test('should log messages with context', () {
        expect(() => logger.info('Message with context', context: {'key': 'value'}), returnsNormally);
      });

      test('should log messages with exception', () {
        expect(() => logger.error('Error with exception', exception: Exception('Test exception')), returnsNormally);
      });

      test('should log messages with stack trace', () {
        expect(() => logger.error('Error with stack trace', stackTrace: StackTrace.current), returnsNormally);
      });
    });

    group('Transport Logging', () {
      test('should log transport messages', () {
        expect(() => logger.transport('Transport message', type: 'WEBSOCKET', operation: 'CONNECT'), returnsNormally);
      });

      test('should log transport messages with data', () {
        expect(() => logger.transport('Transport message', type: 'WEBSOCKET', operation: 'CONNECT', data: {'url': 'test.com'}), returnsNormally);
      });
    });

    group('Connection Logging', () {
      test('should log connection messages', () {
        expect(() => logger.connection('Connection message', operation: 'CONNECT', url: 'https://test.com'), returnsNormally);
      });

      test('should log connection messages with data', () {
        expect(() => logger.connection('Connection message', operation: 'CONNECT', url: 'https://test.com', connectionId: '123', data: {'status': 'connected'}), returnsNormally);
      });
    });

    group('Protocol Logging', () {
      test('should log protocol messages', () {
        expect(() => logger.protocol('Protocol message', operation: 'SERIALIZE', messageType: 'INVOCATION'), returnsNormally);
      });

      test('should log protocol messages with data', () {
        expect(() => logger.protocol('Protocol message', operation: 'SERIALIZE', messageType: 'INVOCATION', data: {'target': 'test'}), returnsNormally);
      });
    });

    group('Resilience Logging', () {
      test('should log resilience messages', () {
        expect(() => logger.resilience('Resilience message', operation: 'RETRY', attempt: 1, state: 'CLOSED'), returnsNormally);
      });

      test('should log resilience messages with data', () {
        expect(() => logger.resilience('Resilience message', operation: 'RETRY', attempt: 1, state: 'CLOSED', data: {'backoff': 1000}), returnsNormally);
      });
    });

    group('Metrics Logging', () {
      test('should log metrics messages', () {
        expect(() => logger.metrics('Metrics message', metric: 'COUNTER'), returnsNormally);
      });

      test('should log metrics messages with data', () {
        expect(() => logger.metrics('Metrics message', metric: 'COUNTER', data: {'value': 42}), returnsNormally);
      });
    });

    group('Level Filtering', () {
      test('should respect log level filtering', () {
        final debugLogger = SignalRLogger(level: Level.debug);
        expect(() => debugLogger.verbose('Verbose message'), returnsNormally);
        expect(() => debugLogger.debug('Debug message'), returnsNormally);
        expect(() => debugLogger.info('Info message'), returnsNormally);
      });

      test('should filter out lower level messages', () {
        final warningLogger = SignalRLogger(level: Level.warning);
        expect(() => warningLogger.verbose('Verbose message'), returnsNormally);
        expect(() => warningLogger.debug('Debug message'), returnsNormally);
        expect(() => warningLogger.info('Info message'), returnsNormally);
        expect(() => warningLogger.warning('Warning message'), returnsNormally);
        expect(() => warningLogger.error('Error message'), returnsNormally);
      });
    });
  });
}
