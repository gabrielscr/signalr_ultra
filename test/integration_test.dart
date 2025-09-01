import 'package:flutter_test/flutter_test.dart';
import 'package:signalr_ultra/signalr_ultra.dart';

void main() {
  group('SignalR Ultra - Testes de Integração', () {
    test('deve criar um ConnectionBuilder com configurações', () {
      final builder = ConnectionBuilder()
          .withUrl('https://example.com/hub')
          .withHeaders({'Authorization': 'Bearer token'})
          .withTimeout(const Duration(seconds: 30));

      expect(builder, isNotNull);
    });

    test('deve criar um SignalRBuilder com configurações', () {
      final builder = SignalRBuilder()
          .withUrl('https://example.com/hub')
          .withTransport(TransportType.webSocket);

      expect(builder, isNotNull);
    });

    test('deve ter todos os estados de conexão disponíveis', () {
      expect(ConnectionState.values.length, equals(6));
      expect(ConnectionState.disconnected, isNotNull);
      expect(ConnectionState.connecting, isNotNull);
      expect(ConnectionState.connected, isNotNull);
      expect(ConnectionState.disconnecting, isNotNull);
      expect(ConnectionState.reconnecting, isNotNull);
      expect(ConnectionState.failed, isNotNull);
    });

    test('deve criar ConnectionMetadata com todos os campos', () {
      final metadata = ConnectionMetadata(
        connectionId: 'test-connection-id',
        baseUrl: 'https://example.com/hub',
        connectedAt: DateTime.now(),
        uptime: const Duration(seconds: 10),
        headers: {'Authorization': 'Bearer token'},
      );

      expect(metadata.connectionId, equals('test-connection-id'));
      expect(metadata.baseUrl, equals('https://example.com/hub'));
      expect(metadata.headers, equals({'Authorization': 'Bearer token'}));
      expect(metadata.messageCount, equals(0));
      expect(metadata.errorCount, equals(0));
    });

    test('deve serializar e deserializar ConnectionMetadata', () {
      final original = ConnectionMetadata(
        connectionId: 'test-connection-id',
        baseUrl: 'https://example.com/hub',
        connectedAt: DateTime.now(),
        uptime: const Duration(seconds: 10),
        headers: {'Authorization': 'Bearer token'},
      );

      final json = original.toJson();
      final deserialized = ConnectionMetadata.fromJson(json);

      expect(deserialized.connectionId, equals(original.connectionId));
      expect(deserialized.baseUrl, equals(original.baseUrl));
      expect(deserialized.headers, equals(original.headers));
    });

    test('deve criar copyWith de ConnectionMetadata', () {
      final original = ConnectionMetadata(
        connectionId: 'test-connection-id',
        baseUrl: 'https://example.com/hub',
        connectedAt: DateTime.now(),
        uptime: const Duration(seconds: 10),
      );

      final updated = original.copyWith(
        messageCount: 5,
        errorCount: 1,
        headers: {'Authorization': 'Bearer token'},
      );

      expect(updated.connectionId, equals(original.connectionId));
      expect(updated.messageCount, equals(5));
      expect(updated.errorCount, equals(1));
      expect(updated.headers, equals({'Authorization': 'Bearer token'}));
    });

    test('deve ter interfaces de transport disponíveis', () {
      expect(TransportType.values.length, equals(4));
      expect(TransportType.webSocket, isNotNull);
      expect(TransportType.serverSentEvents, isNotNull);
      expect(TransportType.longPolling, isNotNull);
      expect(TransportType.auto, isNotNull);
    });

    test('deve ter níveis de log disponíveis', () {
      expect(LogLevel.values.length, equals(6));
      expect(LogLevel.trace, isNotNull);
      expect(LogLevel.debug, isNotNull);
      expect(LogLevel.info, isNotNull);
      expect(LogLevel.warning, isNotNull);
      expect(LogLevel.error, isNotNull);
      expect(LogLevel.fatal, isNotNull);
    });

    test('deve ter políticas de retry disponíveis', () {
      expect(ExponentialBackoffRetryPolicy(), isNotNull);
    });
  });
}
