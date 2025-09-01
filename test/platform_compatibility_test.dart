import 'package:flutter_test/flutter_test.dart';
import 'package:signalr_ultra/src/utils/platform_compatibility.dart';

void main() {
  group('PlatformCompatibility Tests', () {
    test('should detect web platform correctly', () {
      // This test should not throw Platform._version error
      expect(() => PlatformCompatibility.isWeb, returnsNormally);
      expect(() => PlatformCompatibility.isNative, returnsNormally);
    });

    test('should create WebSocket connection without Platform._version error', () async {
      // This test should not throw the Platform._version error
      expect(
        () => PlatformCompatibility.createWebSocketConnection(
          url: 'ws://localhost:8080',
          headers: {'Authorization': 'Bearer test'},
          timeout: const Duration(seconds: 5),
        ),
        returnsNormally,
      );
    });

    test('should create HTTP client without Platform._version error', () async {
      // This test should not throw the Platform._version error
      expect(
        () => PlatformCompatibility.createHttpClient(),
        returnsNormally,
      );
    });

    test('should handle web platform detection gracefully', () {
      // Test that the platform detection doesn't crash
      final isWeb = PlatformCompatibility.isWeb;
      final isNative = PlatformCompatibility.isNative;
      
      // At least one should be true
      expect(isWeb || isNative, isTrue);
      
      // They should be opposite
      expect(isWeb, isNot(isNative));
    });
  });
}
