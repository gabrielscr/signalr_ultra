import 'package:flutter_test/flutter_test.dart';
import 'package:signalr_ultra/signalr_ultra.dart';

void main() {
  group('AutoHealing Tests', () {
    late SignalRClient mockClient;

    setUp(() {
      final builder = SignalRBuilder();
      builder.withUrl('https://test.com/hub');
      mockClient = builder.build();
    });

    test('should create AutoHealing instance', () {
      final autoHealing = AutoHealing(client: mockClient);
      expect(autoHealing, isNotNull);
    });

    test('should have default configuration', () {
      final autoHealing = AutoHealing(client: mockClient);
      expect(autoHealing.maxAttempts, 10);
      expect(autoHealing.attemptCount, 0);
      expect(autoHealing.isReconnecting, false);
    });

    test('should create with custom configuration', () {
      final autoHealing = AutoHealing(
        client: mockClient,
        initialDelay: Duration(seconds: 5),
        maxDelay: Duration(seconds: 60),
        maxAttempts: 5,
        backoffMultiplier: 1.5,
      );
      
      expect(autoHealing.maxAttempts, 5);
      expect(autoHealing.attemptCount, 0);
    });

    test('should handle reconnection state', () {
      final autoHealing = AutoHealing(client: mockClient);
      
      expect(autoHealing.isReconnecting, false);
      expect(autoHealing.attemptCount, 0);
    });

    test('should force reconnection', () async {
      final autoHealing = AutoHealing(client: mockClient);
      
      expect(() => autoHealing.forceReconnect(), returnsNormally);
    });

    test('should stop auto-healing', () {
      final autoHealing = AutoHealing(client: mockClient);
      
      expect(() => autoHealing.stop(), returnsNormally);
      expect(autoHealing.isReconnecting, false);
    });

    test('should dispose correctly', () {
      final autoHealing = AutoHealing(client: mockClient);
      expect(() => autoHealing.dispose(), returnsNormally);
    });
  });

  group('AutoHealingConfig Tests', () {
    test('should create default configuration', () {
      final config = AutoHealingConfig.default_;
      
      expect(config.initialDelay, Duration(seconds: 1));
      expect(config.maxDelay, Duration(minutes: 1));
      expect(config.maxAttempts, 10);
      expect(config.backoffMultiplier, 2.0);
      expect(config.enabled, true);
    });

    test('should create aggressive configuration', () {
      final config = AutoHealingConfig.aggressive;
      
      expect(config.initialDelay, Duration(milliseconds: 100));
      expect(config.maxDelay, Duration(seconds: 10));
      expect(config.maxAttempts, 20);
      expect(config.backoffMultiplier, 1.5);
      expect(config.enabled, true);
    });

    test('should create conservative configuration', () {
      final config = AutoHealingConfig.conservative;
      
      expect(config.initialDelay, Duration(seconds: 5));
      expect(config.maxDelay, Duration(minutes: 5));
      expect(config.maxAttempts, 5);
      expect(config.backoffMultiplier, 3.0);
      expect(config.enabled, true);
    });

    test('should create custom configuration', () {
      final config = AutoHealingConfig(
        initialDelay: Duration(seconds: 2),
        maxDelay: Duration(seconds: 30),
        maxAttempts: 15,
        backoffMultiplier: 2.5,
        enabled: false,
      );
      
      expect(config.initialDelay, Duration(seconds: 2));
      expect(config.maxDelay, Duration(seconds: 30));
      expect(config.maxAttempts, 15);
      expect(config.backoffMultiplier, 2.5);
      expect(config.enabled, false);
    });

    test('should handle const constructor', () {
      const config = AutoHealingConfig();
      
      expect(config.initialDelay, Duration(seconds: 1));
      expect(config.maxDelay, Duration(minutes: 1));
      expect(config.maxAttempts, 10);
      expect(config.backoffMultiplier, 2.0);
      expect(config.enabled, true);
    });
  });
}
