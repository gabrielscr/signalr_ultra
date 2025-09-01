import 'package:flutter_test/flutter_test.dart';
import 'package:signalr_ultra/signalr_ultra.dart';

void main() {
  group('SignalR Ultra - Basic Tests', () {
    test('should export main classes', () {
      expect(ConnectionState.values, isNotEmpty);
      expect(ConnectionState.connected, isNotNull);
      expect(ConnectionState.disconnected, isNotNull);
      expect(ConnectionState.connecting, isNotNull);
    });

    test('should have builders available', () {
      expect(ConnectionBuilder, isNotNull);
      expect(SignalRBuilder, isNotNull);
    });

    test('should have interfaces available', () {
      expect(TransportInterface, isNotNull);
      expect(ProtocolInterface, isNotNull);
      expect(RetryPolicy, isNotNull);
      expect(ObservabilityInterface, isNotNull);
    });

    test('should have entities available', () {
      expect(ConnectionState, isNotNull);
    });
  });
}
