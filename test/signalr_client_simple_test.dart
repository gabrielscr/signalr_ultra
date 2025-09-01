import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:signalr_ultra/signalr_ultra.dart';

void main() {
  group('SignalRClient Simple Tests', () {
    late SignalRClient client;

    setUp(() {
      client = SignalRClient(
        transport: WebSocketTransport(logger: SignalRLogger()),
        protocol: JsonProtocol(),
        circuitBreaker: SimpleCircuitBreaker(),
        observability: SimpleObservability(),
      );
    });

    group('Constructor Tests', () {
      test('should create client with all required dependencies', () {
        expect(client, isNotNull);
        expect(client.state, equals(ConnectionState.disconnected));
        expect(client.isConnected, isFalse);
        expect(client.metadata, isNull);
      });
    });

    group('State Management', () {
      test('should provide state stream', () {
        expect(client.stateStream, isA<Stream<ConnectionState>>());
      });

      test('should provide metadata stream', () {
        expect(client.metadataStream, isA<Stream<ConnectionMetadata>>());
      });

      test('should update state correctly', () {
        expect(client.state, equals(ConnectionState.disconnected));
        expect(client.isConnected, isFalse);
      });
    });

    group('Message Handling', () {
      test('should register method handlers', () {
        final handler = (List<dynamic> args) {};
        client.on('testMethod', handler);

        expect(client.statistics['methodHandlers'], equals(1));
      });

      test('should remove method handlers', () {
        final handler = (List<dynamic> args) {};
        client.on('testMethod', handler);
        expect(client.statistics['methodHandlers'], equals(1));

        client.off('testMethod');
        expect(client.statistics['methodHandlers'], equals(0));
      });

      test('should handle multiple handlers for same method', () {
        final handler1 = (List<dynamic> args) {};
        final handler2 = (List<dynamic> args) {};

        client.on('testMethod', handler1);
        client.on('testMethod', handler2);

        expect(client.statistics['methodHandlers'], equals(1));
      });
    });

    group('Statistics Tests', () {
      test('should provide connection statistics', () {
        final stats = client.statistics;

        expect(stats['state'], isNotNull);
        expect(stats['isConnected'], isFalse);
        expect(stats['pendingInvocations'], equals(0));
        expect(stats['activeStreams'], equals(0));
        expect(stats['methodHandlers'], equals(0));
        expect(stats['circuitBreaker'], isNotNull);
        expect(stats['metrics'], isNotNull);
      });

      test('should update statistics when handlers are added', () {
        final initialStats = client.statistics;
        expect(initialStats['methodHandlers'], equals(0));

        client.on('testMethod', (args) {});
        final updatedStats = client.statistics;
        expect(updatedStats['methodHandlers'], equals(1));
      });
    });

    group('Error Handling', () {
      test('should handle invoke when not connected', () {
        expect(
          () => client.invoke(method: 'testMethod'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle stream when not connected', () {
        expect(
          () => client.stream(method: 'testMethod'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle sendMessage when not connected', () {
        expect(
          () => client.sendMessage(method: 'testMethod'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Connection Management', () {
      test('should handle disconnect when not connected', () async {
        expect(() => client.disconnect(), returnsNormally);
      });
    });
  });
}
