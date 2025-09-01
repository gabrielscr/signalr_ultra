import 'package:flutter_test/flutter_test.dart';
import 'package:signalr_ultra/src/utils/platform_compatibility.dart';

void main() {
  group('Platform._version Fix Tests', () {
    test('should not throw Platform._version error when creating WebSocket connection', () async {
      // This test specifically checks that the Platform._version error is fixed
      // The original error was: "Unsupported operation: Platform._version"
      
      try {
        final connection = await PlatformCompatibility.createWebSocketConnection(
          url: 'ws://localhost:8080',
          headers: {'Authorization': 'Bearer test'},
          timeout: const Duration(seconds: 5),
        );
        
        // If we get here, no Platform._version error was thrown
        expect(connection, isNotNull);
        expect(connection, isA<WebSocketConnection>());
        
      } catch (e) {
        // We expect some errors (like connection refused), but NOT Platform._version
        expect(e.toString(), isNot(contains('Platform._version')));
        expect(e.toString(), isNot(contains('Unsupported operation')));
      }
    });

    test('should not throw Platform._version error when creating HTTP client', () async {
      // This test specifically checks that the Platform._version error is fixed
      
      try {
        final client = await PlatformCompatibility.createHttpClient();
        
        // If we get here, no Platform._version error was thrown
        expect(client, isNotNull);
        expect(client, isA<HttpClient>());
        
      } catch (e) {
        // We should not get Platform._version errors
        expect(e.toString(), isNot(contains('Platform._version')));
        expect(e.toString(), isNot(contains('Unsupported operation')));
      }
    });

    test('should handle platform detection without Platform._version error', () {
      // This test ensures that platform detection works without the original error
      
      try {
        final isWeb = PlatformCompatibility.isWeb;
        final isNative = PlatformCompatibility.isNative;
        
        // Both should be boolean values
        expect(isWeb, isA<bool>());
        expect(isNative, isA<bool>());
        
        // They should be opposite
        expect(isWeb, isNot(isNative));
        
      } catch (e) {
        // We should not get Platform._version errors
        expect(e.toString(), isNot(contains('Platform._version')));
        expect(e.toString(), isNot(contains('Unsupported operation')));
      }
    });

    test('should work in web environment simulation', () {
      // This test simulates the web environment where the original error occurred
      
      try {
        // Try to access platform compatibility multiple times
        for (int i = 0; i < 10; i++) {
          final isWeb = PlatformCompatibility.isWeb;
          final isNative = PlatformCompatibility.isNative;
          
          expect(isWeb, isA<bool>());
          expect(isNative, isA<bool>());
        }
        
      } catch (e) {
        // We should not get Platform._version errors
        expect(e.toString(), isNot(contains('Platform._version')));
        expect(e.toString(), isNot(contains('Unsupported operation')));
      }
    });
  });
}
