import 'dart:async';
import 'dart:math';

import '../core/domain/entities/connection_state.dart';
import '../core/domain/interfaces/observability_interface.dart';
import '../signalr_client.dart';

/// Auto-healing system for SignalR connections with exponential backoff
class AutoHealing {
  AutoHealing({
    required SignalRClient client,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(minutes: 1),
    int maxAttempts = 10,
    double backoffMultiplier = 2.0,
    ObservabilityInterface? observability,
  }) : _client = client,
       _initialDelay = initialDelay,
       _maxDelay = maxDelay,
       _maxAttempts = maxAttempts,
       _backoffMultiplier = backoffMultiplier,
       _observability = observability {
    _setupConnectionMonitoring();
  }

  final SignalRClient _client;
  final Duration _initialDelay;
  final Duration _maxDelay;
  final int _maxAttempts;
  final double _backoffMultiplier;
  final ObservabilityInterface? _observability;
  
  Timer? _reconnectTimer;
  int _attemptCount = 0;
  bool _isReconnecting = false;
  final Random _random = Random();

  /// Sets up connection state monitoring to trigger reconnection
  void _setupConnectionMonitoring() {
    _client.stateStream.listen((state) {
      if (state == ConnectionState.disconnected && !_isReconnecting) {
        _scheduleReconnect();
      } else if (state == ConnectionState.connected) {
        _resetReconnectAttempts();
      }
    });
  }

  /// Schedules a reconnection attempt with exponential backoff
  void _scheduleReconnect() {
    if (_attemptCount >= _maxAttempts) {
      _log('Maximum reconnection attempts reached');
      return;
    }

    if (_isReconnecting) {
      _log('Reconnection already in progress');
      return;
    }

    _isReconnecting = true;
    _attemptCount++;

    final delay = _calculateDelay();
    _log('Scheduling reconnection in ${delay.inSeconds} seconds (attempt $_attemptCount/$_maxAttempts)');

    _reconnectTimer = Timer(delay, () {
      _attemptReconnect();
    });
  }

  /// Calculates delay using exponential backoff with jitter
  /// Formula: delay = initialDelay * (backoffMultiplier ^ (attempt - 1)) * (1 + randomJitter)
  Duration _calculateDelay() {
    final baseDelay = _initialDelay.inMilliseconds * pow(_backoffMultiplier, _attemptCount - 1);

    // Add 10% jitter to prevent thundering herd problem
    final jitter = _random.nextDouble() * 0.1;
    final delayWithJitter = baseDelay * (1 + jitter);
    
    return Duration(milliseconds: delayWithJitter.clamp(0, _maxDelay.inMilliseconds).toInt());
  }

  /// Attempts to reconnect using original connection parameters
  Future<void> _attemptReconnect() async {
    try {
      _log('Attempting to reconnect...');
      
      await _client.connect(
        url: _client.metadata?.baseUrl ?? '',
        headers: _client.metadata?.headers,
      );
      
      _log('Reconnection successful!');
      _resetReconnectAttempts();
      
    } catch (e) {
      _log('Reconnection failed: $e');
      _isReconnecting = false;
      
      // Schedule next attempt if max attempts not reached
      if (_attemptCount < _maxAttempts) {
        _scheduleReconnect();
      }
    }
  }

  /// Resets reconnection attempt counter
  void _resetReconnectAttempts() {
    _attemptCount = 0;
    _isReconnecting = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _log('Reconnection attempt counter reset');
  }

  /// Forces an immediate reconnection attempt
  Future<void> forceReconnect() async {
    _log('Forcing reconnection...');
    _resetReconnectAttempts();
    await _attemptReconnect();
  }

  /// Stops the auto-healing process
  void stop() {
    _log('Stopping auto-healing');
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
  }

  /// Returns whether currently attempting to reconnect
  bool get isReconnecting => _isReconnecting;

  /// Returns current attempt count
  int get attemptCount => _attemptCount;

  /// Returns maximum number of attempts
  int get maxAttempts => _maxAttempts;

  void _log(String message) {
    _observability?.log(LogLevel.debug, '[AutoHealing] $message');
  }

  /// Disposes the auto-healing system
  void dispose() {
    stop();
  }
}

/// Configuration for auto-healing behavior
class AutoHealingConfig {
  const AutoHealingConfig({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 1),
    this.maxAttempts = 10,
    this.backoffMultiplier = 2.0,
    this.enabled = true,
  });

  final Duration initialDelay;
  final Duration maxDelay;
  final int maxAttempts;
  final double backoffMultiplier;
  final bool enabled;

  /// Default configuration
  static const AutoHealingConfig default_ = AutoHealingConfig();

  /// Aggressive configuration for fast reconnection
  static const AutoHealingConfig aggressive = AutoHealingConfig(
    initialDelay: Duration(milliseconds: 100),
    maxDelay: Duration(seconds: 10),
    maxAttempts: 20,
    backoffMultiplier: 1.5,
  );

  /// Conservative configuration for slow reconnection
  static const AutoHealingConfig conservative = AutoHealingConfig(
    initialDelay: Duration(seconds: 5),
    maxDelay: Duration(minutes: 5),
    maxAttempts: 5,
    backoffMultiplier: 3,
  );
}
