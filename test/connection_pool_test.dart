import 'package:flutter_test/flutter_test.dart';
import 'package:signalr_ultra/signalr_ultra.dart';

void main() {
  group('ConnectionPool Tests', () {
    late ConnectionPool pool;

    setUp(() {
      pool = ConnectionPool();
    });

    group('Constructor and Initialization', () {
      test('should create pool with default values', () {
        expect(pool, isNotNull);
        expect(pool.activeConnections, equals(0));
        expect(pool.idleConnections, equals(0));
        expect(pool.totalConnections, equals(0));
      });

      test('should create pool with custom configuration', () {
        final customPool = ConnectionPool(
          maxConnections: 5,
          idleTimeout: Duration(minutes: 10),
        );
        expect(customPool, isNotNull);
      });
    });

    group('Connection Statistics', () {
      test('should track active connections', () {
        expect(pool.activeConnections, equals(0));
        expect(pool.idleConnections, equals(0));
        expect(pool.totalConnections, equals(0));
      });

      test('should provide events stream', () {
        expect(pool.events, isA<Stream<ConnectionPoolEvent>>());
      });
    });

    group('Connection Management', () {
      test('should throw when getting connection (not implemented)', () async {
        expect(
          () => pool.getConnection(url: 'https://test.com'),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('should release connection', () {
        expect(() => pool.releaseConnection('https://test.com', null), returnsNormally);
      });

      test('should close connection', () async {
        expect(() => pool.closeConnection('https://test.com', null), returnsNormally);
      });
    });

    group('Pool Lifecycle', () {
      test('should close all connections', () async {
        expect(() => pool.closeAll(), returnsNormally);
      });

      // test('should dispose pool', () async {
      //   expect(() => pool.dispose(), returnsNormally);
      // });
    });

    group('ConnectionPoolEvent Tests', () {
      test('should create connection created event', () {
        final event = ConnectionPoolEvent.connectionCreated('test-key');
        expect(event.type, equals(ConnectionPoolEventType.connectionCreated));
        expect(event.connectionKey, equals('test-key'));
        expect(event.timestamp, isNotNull);
      });

      test('should create connection reused event', () {
        final event = ConnectionPoolEvent.connectionReused('test-key');
        expect(event.type, equals(ConnectionPoolEventType.connectionReused));
        expect(event.connectionKey, equals('test-key'));
        expect(event.timestamp, isNotNull);
      });

      test('should create connection released event', () {
        final event = ConnectionPoolEvent.connectionReleased('test-key');
        expect(event.type, equals(ConnectionPoolEventType.connectionReleased));
        expect(event.connectionKey, equals('test-key'));
        expect(event.timestamp, isNotNull);
      });

      test('should create connection closed event', () {
        final event = ConnectionPoolEvent.connectionClosed('test-key');
        expect(event.type, equals(ConnectionPoolEventType.connectionClosed));
        expect(event.connectionKey, equals('test-key'));
        expect(event.timestamp, isNotNull);
      });

      test('should create connection timed out event', () {
        final event = ConnectionPoolEvent.connectionTimedOut('test-key');
        expect(event.type, equals(ConnectionPoolEventType.connectionTimedOut));
        expect(event.connectionKey, equals('test-key'));
        expect(event.timestamp, isNotNull);
      });

      test('should create all connections closed event', () {
        final event = ConnectionPoolEvent.allConnectionsClosed();
        expect(event.type, equals(ConnectionPoolEventType.allConnectionsClosed));
        expect(event.connectionKey, isNull);
        expect(event.timestamp, isNotNull);
      });
    });

    group('ConnectionPoolEventType Tests', () {
      test('should have all required event types', () {
        expect(ConnectionPoolEventType.values, hasLength(6));
        expect(ConnectionPoolEventType.values, contains(ConnectionPoolEventType.connectionCreated));
        expect(ConnectionPoolEventType.values, contains(ConnectionPoolEventType.connectionReused));
        expect(ConnectionPoolEventType.values, contains(ConnectionPoolEventType.connectionReleased));
        expect(ConnectionPoolEventType.values, contains(ConnectionPoolEventType.connectionClosed));
        expect(ConnectionPoolEventType.values, contains(ConnectionPoolEventType.connectionTimedOut));
        expect(ConnectionPoolEventType.values, contains(ConnectionPoolEventType.allConnectionsClosed));
      });
    });

    group('Error Handling', () {
      test('should handle release of non-existent connection', () {
        expect(() => pool.releaseConnection('non-existent', null), returnsNormally);
      });

      test('should handle close of non-existent connection', () async {
        expect(() => pool.closeConnection('non-existent', null), returnsNormally);
      });
    });
  });
}
