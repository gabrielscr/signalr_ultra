import 'dart:async';

/// Log levels for observability
enum LogLevel {
  /// Trace level for detailed debugging
  trace,
  
  /// Debug level for debugging information
  debug,
  
  /// Info level for general information
  info,
  
  /// Warning level for warnings
  warning,
  
  /// Error level for errors
  error,
  
  /// Fatal level for fatal errors
  fatal,
}

/// Metric types
enum MetricType {
  /// Counter metric (increments)
  counter,
  
  /// Gauge metric (current value)
  gauge,
  
  /// Histogram metric (distribution)
  histogram,
  
  /// Timer metric (duration)
  timer,
}

/// Observability interface for logging and metrics
abstract class ObservabilityInterface {
  /// Logs a message with specified level
  void log(LogLevel level, String message, [Map<String, dynamic>? context]);
  
  /// Logs an error with stack trace
  void logError(String message, [Object? error, StackTrace? stackTrace]);
  
  /// Increments a counter metric
  void incrementCounter(String name, [Map<String, String>? labels]);
  
  /// Records a gauge metric
  void recordGauge(String name, double value, [Map<String, String>? labels]);
  
  /// Records a histogram metric
  void recordHistogram(String name, double value, [Map<String, String>? labels]);
  
  /// Records a timer metric
  void recordTimer(String name, Duration duration, [Map<String, String>? labels]);
  
  /// Creates a timer for measuring duration
  TimerMetric startTimer(String name, [Map<String, String>? labels]);
  
  /// Stream of log events
  Stream<LogEvent> get logStream;
  
  /// Stream of metric events
  Stream<MetricEvent> get metricStream;
  
  /// Gets current metrics
  Map<String, dynamic> get metrics;
  
  /// Exports metrics in Prometheus format
  String exportMetrics();
}

/// Log event
class LogEvent {

  LogEvent({
    required this.timestamp,
    required this.level,
    required this.message,
    this.context,
    this.source,
  });
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Map<String, dynamic>? context;
  final String? source;

  Map<String, dynamic> toJson() => {
      'timestamp': timestamp.toIso8601String(),
      'level': level.toString(),
      'message': message,
      'context': context,
      'source': source,
    };
}

/// Metric event
class MetricEvent {

  MetricEvent({
    required this.timestamp,
    required this.type,
    required this.name,
    required this.value,
    this.labels,
  });
  final DateTime timestamp;
  final MetricType type;
  final String name;
  final double value;
  final Map<String, String>? labels;

  Map<String, dynamic> toJson() => {
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
      'name': name,
      'value': value,
      'labels': labels,
    };
}

/// Timer metric for measuring duration
class TimerMetric {

  TimerMetric({
    required this.name,
    this.labels,
    required this.startTime,
    required this.observability,
  });
  final String name;
  final Map<String, String>? labels;
  final DateTime startTime;
  final ObservabilityInterface observability;

  /// Stops the timer and records the duration
  void stop() {
    final duration = DateTime.now().difference(startTime);
    observability.recordTimer(name, duration, labels);
  }
}

/// Simple observability implementation
class SimpleObservability implements ObservabilityInterface {
  final StreamController<LogEvent> _logController = 
      StreamController<LogEvent>.broadcast();
  final StreamController<MetricEvent> _metricController = 
      StreamController<MetricEvent>.broadcast();
  
  final Map<String, double> _counters = {};
  final Map<String, double> _gauges = {};
  final Map<String, List<double>> _histograms = {};
  final Map<String, List<Duration>> _timers = {};

  @override
  void log(LogLevel level, String message, [Map<String, dynamic>? context]) {
    final event = LogEvent(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      context: context,
    );
    
    _logController.add(event);
  }

  @override
  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    log(LogLevel.error, message, {
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
    });
  }

  @override
  void incrementCounter(String name, [Map<String, String>? labels]) {
    final key = _getMetricKey(name, labels);
    _counters[key] = (_counters[key] ?? 0) + 1;
    
    _metricController.add(MetricEvent(
      timestamp: DateTime.now(),
      type: MetricType.counter,
      name: name,
      value: _counters[key]!,
      labels: labels,
    ));
  }

  @override
  void recordGauge(String name, double value, [Map<String, String>? labels]) {
    final key = _getMetricKey(name, labels);
    _gauges[key] = value;
    
    _metricController.add(MetricEvent(
      timestamp: DateTime.now(),
      type: MetricType.gauge,
      name: name,
      value: value,
      labels: labels,
    ));
  }

  @override
  void recordHistogram(String name, double value, [Map<String, String>? labels]) {
    final key = _getMetricKey(name, labels);
    _histograms.putIfAbsent(key, () => []).add(value);
    
    _metricController.add(MetricEvent(
      timestamp: DateTime.now(),
      type: MetricType.histogram,
      name: name,
      value: value,
      labels: labels,
    ));
  }

  @override
  void recordTimer(String name, Duration duration, [Map<String, String>? labels]) {
    final key = _getMetricKey(name, labels);
    _timers.putIfAbsent(key, () => []).add(duration);
    
    _metricController.add(MetricEvent(
      timestamp: DateTime.now(),
      type: MetricType.timer,
      name: name,
      value: duration.inMilliseconds.toDouble(),
      labels: labels,
    ));
  }

  @override
  TimerMetric startTimer(String name, [Map<String, String>? labels]) => TimerMetric(
      name: name,
      labels: labels,
      startTime: DateTime.now(),
      observability: this,
    );

  @override
  Stream<LogEvent> get logStream => _logController.stream;

  @override
  Stream<MetricEvent> get metricStream => _metricController.stream;

  @override
  Map<String, dynamic> get metrics => {
      'counters': Map.from(_counters),
      'gauges': Map.from(_gauges),
      'histograms': _histograms.map((key, values) => MapEntry(key, {
        'count': values.length,
        'sum': values.reduce((a, b) => a + b),
        'min': values.reduce((a, b) => a < b ? a : b),
        'max': values.reduce((a, b) => a > b ? a : b),
        'avg': values.reduce((a, b) => a + b) / values.length,
      })),
      'timers': _timers.map((key, values) {
        if (values.isEmpty) {
          return MapEntry(key, {
            'count': 0,
            'total': Duration.zero,
            'min': Duration.zero,
            'max': Duration.zero,
            'avg': Duration.zero,
          });
        }
        return MapEntry(key, {
          'count': values.length,
          'total': values.fold(Duration.zero, (a, b) => a + b),
          'min': values.reduce((a, b) => a < b ? a : b),
          'max': values.reduce((a, b) => a > b ? a : b),
          'avg': Duration(milliseconds: values.fold<int>(0, (a, b) => a + b.inMilliseconds) ~/ values.length),
        });
      }),
    };

  @override
  String exportMetrics() {
    final buffer = StringBuffer();
    
    // Export counters
    for (final entry in _counters.entries) {
      buffer.writeln('# HELP ${entry.key} Counter metric');
      buffer.writeln('# TYPE ${entry.key} counter');
      buffer.writeln('${entry.key} ${entry.value}');
    }
    
    // Export gauges
    for (final entry in _gauges.entries) {
      buffer.writeln('# HELP ${entry.key} Gauge metric');
      buffer.writeln('# TYPE ${entry.key} gauge');
      buffer.writeln('${entry.key} ${entry.value}');
    }
    
    return buffer.toString();
  }

  String _getMetricKey(String name, Map<String, String>? labels) {
    if (labels == null || labels.isEmpty) return name;
    
    final labelPairs = labels.entries
        .map((e) => '${e.key}="${e.value}"')
        .join(',');
    
    return '$name{$labelPairs}';
  }
}
