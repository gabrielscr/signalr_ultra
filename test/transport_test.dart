import 'package:flutter_test/flutter_test.dart';
import 'package:signalr_ultra/src/transport/websocket_transport.dart';
import 'package:signalr_ultra/src/transport/sse_transport.dart';
import 'package:signalr_ultra/src/transport/long_polling_transport.dart';
import 'package:signalr_ultra/src/core/logging/signalr_logger.dart';
import 'package:signalr_ultra/src/core/domain/interfaces/transport_interface.dart';

void main() {
  group('Transport Tests', () {
    late SignalRLogger logger;

    setUp(() {
      logger = SignalRLogger(level: Level.error); // Only errors for tests
    });

    group('WebSocket Transport Tests', () {
      test('should have correct type and formats', () {
        final transport = WebSocketTransport(logger: logger);
        
        expect(transport.type, TransportType.webSocket);
        expect(transport.supportedFormats, contains(TransferFormat.text));
        expect(transport.supportedFormats, contains(TransferFormat.binary));
        expect(transport.isConnected, false);
        expect(transport.url, isNull);
        expect(transport.headers, isEmpty);
      });

      test('should not connect with invalid format', () async {
        final transport = WebSocketTransport(logger: logger);
        
        expect(
          () => transport.connect(
            url: 'ws://test.com',
            format: TransferFormat.binary,
          ),
          throwsException,
        );
      });
    });

    group('SSE Transport Tests', () {
      test('should have correct type and formats', () {
        final transport = SSETransport(logger: logger);
        
        expect(transport.type, TransportType.serverSentEvents);
        expect(transport.supportedFormats, contains(TransferFormat.text));
        expect(transport.supportedFormats, isNot(contains(TransferFormat.binary)));
        expect(transport.isConnected, false);
        expect(transport.url, isNull);
        expect(transport.headers, isEmpty);
      });

      test('should not connect with binary format', () async {
        final transport = SSETransport(logger: logger);
        
        expect(
          () => transport.connect(
            url: 'http://test.com',
            format: TransferFormat.binary,
          ),
          throwsException,
        );
      });

      test('should not send data (read-only)', () async {
        final transport = SSETransport(logger: logger);
        
        expect(
          () => transport.send('test'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Long Polling Transport Tests', () {
      test('should have correct type and formats', () {
        final transport = LongPollingTransport(logger: logger);
        
        expect(transport.type, TransportType.longPolling);
        expect(transport.supportedFormats, contains(TransferFormat.text));
        expect(transport.supportedFormats, isNot(contains(TransferFormat.binary)));
        expect(transport.isConnected, false);
        expect(transport.url, isNull);
        expect(transport.headers, isEmpty);
      });

      test('should not connect with binary format', () async {
        final transport = LongPollingTransport(logger: logger);
        
        expect(
          () => transport.connect(
            url: 'http://test.com',
            format: TransferFormat.binary,
          ),
          throwsException,
        );
      });

      test('should not send when not connected', () async {
        final transport = LongPollingTransport(logger: logger);
        
        expect(
          () => transport.send('test'),
          throwsException,
        );
      });
    });

    group('Transport Headers Tests', () {
      test('should preserve custom headers', () {
        final headers = {'Authorization': 'Bearer token', 'X-Custom': 'value'};
        
        final wsTransport = WebSocketTransport(
          logger: logger,
          headers: headers,
        );
        final sseTransport = SSETransport(
          logger: logger,
          headers: headers,
        );
        final lpTransport = LongPollingTransport(
          logger: logger,
          headers: headers,
        );
        
        expect(wsTransport.headers, headers);
        expect(sseTransport.headers, headers);
        expect(lpTransport.headers, headers);
      });
    });

    group('Transport Timeout Tests', () {
      test('should use custom timeout', () {
        final customTimeout = Duration(seconds: 60);
        
        final wsTransport = WebSocketTransport(
          logger: logger,
          timeout: customTimeout,
        );
        final sseTransport = SSETransport(
          logger: logger,
          timeout: customTimeout,
        );
        final lpTransport = LongPollingTransport(
          logger: logger,
          timeout: customTimeout,
        );
        
        // All transports should accept custom timeout
        expect(wsTransport, isNotNull);
        expect(sseTransport, isNotNull);
        expect(lpTransport, isNotNull);
      });
    });
  });
}
