import 'package:flutter_test/flutter_test.dart';
import 'package:signalr_ultra/signalr_ultra.dart';

void main() {
  group('ConnectionState Tests', () {
    test('should have all expected states', () {
      expect(ConnectionState.values.length, 6);
      expect(ConnectionState.disconnected, isNotNull);
      expect(ConnectionState.connecting, isNotNull);
      expect(ConnectionState.connected, isNotNull);
      expect(ConnectionState.disconnecting, isNotNull);
      expect(ConnectionState.reconnecting, isNotNull);
      expect(ConnectionState.failed, isNotNull);
    });

    test('should be comparable', () {
      expect(ConnectionState.connected, equals(ConnectionState.connected));
      expect(ConnectionState.disconnected, isNot(equals(ConnectionState.connected)));
    });
  });

  group('ConnectionMetadata Tests', () {
    test('should create with required parameters', () {
      final metadata = ConnectionMetadata(
        connectionId: 'test-conn-123',
        baseUrl: 'https://test.com',
        connectedAt: DateTime(2023, 1, 1),
        uptime: Duration(minutes: 5),
      );

      expect(metadata.connectionId, 'test-conn-123');
      expect(metadata.baseUrl, 'https://test.com');
      expect(metadata.connectedAt, DateTime(2023, 1, 1));
      expect(metadata.uptime, Duration(minutes: 5));
      expect(metadata.messageCount, 0);
      expect(metadata.errorCount, 0);
      expect(metadata.lastPingAt, isNull);
      expect(metadata.headers, isNull);
    });

    test('should create with all parameters', () {
      final headers = {'Authorization': 'Bearer token'};
      final lastPingAt = DateTime(2023, 1, 1, 12, 1, 0);
      
      final metadata = ConnectionMetadata(
        connectionId: 'test-conn-123',
        baseUrl: 'https://test.com',
        connectedAt: DateTime(2023, 1, 1, 12, 0, 0),
        lastPingAt: lastPingAt,
        messageCount: 10,
        errorCount: 2,
        uptime: Duration(minutes: 5),
        headers: headers,
      );

      expect(metadata.connectionId, 'test-conn-123');
      expect(metadata.baseUrl, 'https://test.com');
      expect(metadata.lastPingAt, lastPingAt);
      expect(metadata.messageCount, 10);
      expect(metadata.errorCount, 2);
      expect(metadata.headers, headers);
    });

    test('should serialize to JSON', () {
      final metadata = ConnectionMetadata(
        connectionId: 'test-conn-123',
        baseUrl: 'https://test.com',
        connectedAt: DateTime(2023, 1, 1, 12, 0, 0),
        lastPingAt: DateTime(2023, 1, 1, 12, 1, 0),
        messageCount: 10,
        errorCount: 2,
        uptime: Duration(minutes: 5),
        headers: {'Authorization': 'Bearer token'},
      );

      final json = metadata.toJson();

      expect(json['connectionId'], 'test-conn-123');
      expect(json['baseUrl'], 'https://test.com');
      expect(json['connectedAt'], '2023-01-01T12:00:00.000');
      expect(json['lastPingAt'], '2023-01-01T12:01:00.000');
      expect(json['messageCount'], 10);
      expect(json['errorCount'], 2);
      expect(json['uptime'], 300000); // 5 minutes in milliseconds
      expect(json['headers'], {'Authorization': 'Bearer token'});
    });

    test('should deserialize from JSON', () {
      final json = {
        'connectionId': 'test-conn-123',
        'baseUrl': 'https://test.com',
        'connectedAt': '2023-01-01T12:00:00.000',
        'lastPingAt': '2023-01-01T12:01:00.000',
        'messageCount': 10,
        'errorCount': 2,
        'uptime': 300000,
        'headers': {'Authorization': 'Bearer token'},
      };

      final metadata = ConnectionMetadata.fromJson(json);

      expect(metadata.connectionId, 'test-conn-123');
      expect(metadata.baseUrl, 'https://test.com');
      expect(metadata.connectedAt, DateTime(2023, 1, 1, 12, 0, 0));
      expect(metadata.lastPingAt, DateTime(2023, 1, 1, 12, 1, 0));
      expect(metadata.messageCount, 10);
      expect(metadata.errorCount, 2);
      expect(metadata.uptime, Duration(minutes: 5));
      expect(metadata.headers, {'Authorization': 'Bearer token'});
    });

    test('should deserialize from JSON with null values', () {
      final json = {
        'connectionId': 'test-conn-123',
        'baseUrl': 'https://test.com',
        'connectedAt': '2023-01-01T12:00:00.000',
        'uptime': 300000,
      };

      final metadata = ConnectionMetadata.fromJson(json);

      expect(metadata.connectionId, 'test-conn-123');
      expect(metadata.baseUrl, 'https://test.com');
      expect(metadata.lastPingAt, isNull);
      expect(metadata.messageCount, 0);
      expect(metadata.errorCount, 0);
      expect(metadata.headers, isNull);
    });

    test('should copy with new values', () {
      final original = ConnectionMetadata(
        connectionId: 'test-conn-123',
        baseUrl: 'https://test.com',
        connectedAt: DateTime(2023, 1, 1),
        uptime: Duration(minutes: 5),
      );

      final updated = original.copyWith(
        messageCount: 10,
        errorCount: 2,
        uptime: Duration(minutes: 10),
      );

      expect(updated.connectionId, 'test-conn-123');
      expect(updated.baseUrl, 'https://test.com');
      expect(updated.messageCount, 10);
      expect(updated.errorCount, 2);
      expect(updated.uptime, Duration(minutes: 10));
      expect(updated.lastPingAt, isNull);
      expect(updated.headers, isNull);
    });

    test('should copy with all new values', () {
      final original = ConnectionMetadata(
        connectionId: 'test-conn-123',
        baseUrl: 'https://test.com',
        connectedAt: DateTime(2023, 1, 1),
        uptime: Duration(minutes: 5),
      );

      final newConnectedAt = DateTime(2023, 1, 2);
      final newLastPingAt = DateTime(2023, 1, 2, 12, 1, 0);
      final newHeaders = {'New-Auth': 'new-token'};

      final updated = original.copyWith(
        connectionId: 'new-conn-456',
        baseUrl: 'https://new-test.com',
        connectedAt: newConnectedAt,
        lastPingAt: newLastPingAt,
        messageCount: 20,
        errorCount: 5,
        uptime: Duration(minutes: 15),
        headers: newHeaders,
      );

      expect(updated.connectionId, 'new-conn-456');
      expect(updated.baseUrl, 'https://new-test.com');
      expect(updated.connectedAt, newConnectedAt);
      expect(updated.lastPingAt, newLastPingAt);
      expect(updated.messageCount, 20);
      expect(updated.errorCount, 5);
      expect(updated.uptime, Duration(minutes: 15));
      expect(updated.headers, newHeaders);
    });

    test('should be equal when properties match', () {
      final metadata1 = ConnectionMetadata(
        connectionId: 'test-conn-123',
        baseUrl: 'https://test.com',
        connectedAt: DateTime(2023, 1, 1),
        uptime: Duration(minutes: 5),
      );

      final metadata2 = ConnectionMetadata(
        connectionId: 'test-conn-123',
        baseUrl: 'https://test.com',
        connectedAt: DateTime(2023, 1, 1),
        uptime: Duration(minutes: 5),
      );

      expect(metadata1, equals(metadata2));
      expect(metadata1.hashCode, equals(metadata2.hashCode));
    });

    test('should not be equal when properties differ', () {
      final metadata1 = ConnectionMetadata(
        connectionId: 'test-conn-123',
        baseUrl: 'https://test.com',
        connectedAt: DateTime(2023, 1, 1),
        uptime: Duration(minutes: 5),
      );

      final metadata2 = ConnectionMetadata(
        connectionId: 'test-conn-456',
        baseUrl: 'https://test.com',
        connectedAt: DateTime(2023, 1, 1),
        uptime: Duration(minutes: 5),
      );

      expect(metadata1, isNot(equals(metadata2)));
    });

    test('should have correct string representation', () {
      final metadata = ConnectionMetadata(
        connectionId: 'test-conn-123',
        baseUrl: 'https://test.com',
        connectedAt: DateTime(2023, 1, 1),
        uptime: Duration(minutes: 5),
      );

      final str = metadata.toString();
      expect(str, contains('test-conn-123'));
      expect(str, contains('https://test.com'));
      expect(str, contains('0:05:00.000000'));
    });
  });
}
