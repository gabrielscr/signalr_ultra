import 'dart:async';

/// Retry policy interface
abstract class RetryPolicy {
  /// Determines if retry should be attempted
  bool shouldRetry(Exception error, int attempt);
  
  /// Gets delay before next retry
  Duration getDelay(int attempt);
  
  /// Maximum number of retry attempts
  int get maxAttempts;
  
  /// Current attempt number
  int get currentAttempt;
  
  /// Resets retry state
  void reset();
}

/// Circuit breaker states
enum CircuitBreakerState {
  /// Circuit is closed (normal operation)
  closed,
  
  /// Circuit is open (failing, no requests allowed)
  open,
  
  /// Circuit is half-open (testing if service recovered)
  halfOpen,
}

/// Circuit breaker interface for fault tolerance
abstract class CircuitBreaker {
  /// Current circuit state
  CircuitBreakerState get state;
  
  /// Stream of state changes
  Stream<CircuitBreakerState> get stateStream;
  
  /// Executes function with circuit breaker protection
  Future<T> execute<T>(Future<T> Function() operation);
  
  /// Records a successful operation
  void recordSuccess();
  
  /// Records a failed operation
  void recordFailure(Exception error);
  
  /// Manually opens the circuit
  void open();
  
  /// Manually closes the circuit
  void close();
  
  /// Gets circuit statistics
  Map<String, dynamic> get statistics;
}

/// Exponential backoff retry policy
class ExponentialBackoffRetryPolicy implements RetryPolicy {

  ExponentialBackoffRetryPolicy({
    int maxAttempts = 5,
    this.initialDelay = const Duration(seconds: 1),
    this.multiplier = 2.0,
    this.maxDelay = const Duration(minutes: 1),
    this.retryableExceptions = const [],
  }) : _maxAttempts = maxAttempts;
  final int _maxAttempts;
  final Duration initialDelay;
  final double multiplier;
  final Duration maxDelay;
  final List<Type> retryableExceptions;
  
  int _currentAttempt = 0;

  @override
  bool shouldRetry(Exception error, int attempt) {
    if (attempt >= _maxAttempts) return false;
    
    if (retryableExceptions.isEmpty) return true;
    
    return retryableExceptions.any((type) => error.runtimeType == type);
  }

  @override
  Duration getDelay(int attempt) {
    final delay = Duration(
      milliseconds: (initialDelay.inMilliseconds * (multiplier * attempt)).round(),
    );
    
    return delay > maxDelay ? maxDelay : delay;
  }

  @override
  int get maxAttempts => _maxAttempts;

  @override
  int get currentAttempt => _currentAttempt;

  @override
  void reset() {
    _currentAttempt = 0;
  }
}

/// Simple circuit breaker implementation
class SimpleCircuitBreaker implements CircuitBreaker {

  SimpleCircuitBreaker({
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 60),
    this.resetTimeout = const Duration(minutes: 1),
  });
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;
  
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  final StreamController<CircuitBreakerState> _stateController = 
      StreamController<CircuitBreakerState>.broadcast();

  @override
  CircuitBreakerState get state => _state;

  @override
  Stream<CircuitBreakerState> get stateStream => _stateController.stream;

  @override
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
        _stateController.add(_state);
      } else {
        throw Exception('Circuit breaker is open');
      }
    }

    try {
      final result = await operation().timeout(timeout);
      recordSuccess();
      return result;
    } catch (e) {
      recordFailure(e as Exception);
      rethrow;
    }
  }

  @override
  void recordSuccess() {
    _failureCount = 0;
    if (_state != CircuitBreakerState.closed) {
      _state = CircuitBreakerState.closed;
      _stateController.add(_state);
    }
  }

  @override
  void recordFailure(Exception error) {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
      _stateController.add(_state);
    }
  }

  @override
  void open() {
    _state = CircuitBreakerState.open;
    _stateController.add(_state);
  }

  @override
  void close() {
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _stateController.add(_state);
  }

  @override
  Map<String, dynamic> get statistics => {
      'state': _state.toString(),
      'failureCount': _failureCount,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'failureThreshold': failureThreshold,
    };

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;
    return DateTime.now().difference(_lastFailureTime!) > resetTimeout;
  }
}
