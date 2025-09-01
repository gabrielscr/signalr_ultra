import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signalr_ultra/signalr_ultra.dart';

void main() {
  group('ObservabilityInterface Tests', () {
    group('SimpleObservability Tests', () {
      late SimpleObservability observability;

      setUp(() {
        observability = SimpleObservability();
      });

      test('should create with default configuration', () {
        expect(observability, isNotNull);
        expect(observability.metrics, isA<Map<String, dynamic>>());
        expect(observability.logStream, isA<Stream<LogEvent>>());
        expect(observability.metricStream, isA<Stream<MetricEvent>>());
      });

      test('should log messages', () {
        expect(() => observability.log(LogLevel.debug, 'Debug message'), returnsNormally);
        expect(() => observability.log(LogLevel.info, 'Info message'), returnsNormally);
        expect(() => observability.log(LogLevel.warning, 'Warning message'), returnsNormally);
        expect(() => observability.log(LogLevel.error, 'Error message'), returnsNormally);
      });

      test('should log messages with context', () {
        final context = {'userId': '123', 'action': 'connect'};
        expect(() => observability.log(LogLevel.info, 'User connected', context), returnsNormally);
      });

      test('should log errors with exception', () {
        final exception = Exception('Test error');
        expect(() => observability.logError('Operation failed', exception), returnsNormally);
      });

      test('should increment counters', () {
        expect(() => observability.incrementCounter('requests_total'), returnsNormally);
        expect(() => observability.incrementCounter('requests_total', {'method': 'GET'}), returnsNormally);
        expect(() => observability.incrementCounter('errors_total', {'type': 'timeout'}), returnsNormally);
      });

      test('should record gauges', () {
        expect(() => observability.recordGauge('active_connections', 5), returnsNormally);
        expect(() => observability.recordGauge('memory_usage', 1024.5, {'unit': 'MB'}), returnsNormally);
      });

      test('should record histograms', () {
        expect(() => observability.recordHistogram('request_duration', 150), returnsNormally);
        expect(() => observability.recordHistogram('response_size', 1024, {'unit': 'bytes'}), returnsNormally);
      });

      test('should start and stop timers', () async {
        final timer = observability.startTimer('operation_duration');
        expect(timer, isA<TimerMetric>());
        expect(timer.name, 'operation_duration');

        await Future.delayed(Duration(milliseconds: 10));
        expect(() => timer.stop(), returnsNormally);
      });

      test('should provide metrics summary', () {
        observability.incrementCounter('requests_total');
        observability.recordGauge('active_connections', 5);
        observability.recordHistogram('request_duration', 100);

        final metrics = observability.metrics;

        expect(metrics['counters'], isNotNull);
        expect(metrics['gauges'], isNotNull);
        expect(metrics['histograms'], isNotNull);
        expect(metrics['timers'], isNotNull);
      });

      test('should export metrics in Prometheus format', () {
        observability.incrementCounter('requests_total');
        observability.recordGauge('active_connections', 5);

        final export = observability.exportMetrics();

        expect(export, isA<String>());
        expect(export, contains('requests_total'));
        expect(export, contains('active_connections'));
      });
    });

    group('LogLevel Tests', () {
      test('should have correct values', () {
        expect(LogLevel.trace.index, 0);
        expect(LogLevel.debug.index, 1);
        expect(LogLevel.info.index, 2);
        expect(LogLevel.warning.index, 3);
        expect(LogLevel.error.index, 4);
        expect(LogLevel.fatal.index, 5);
      });

      test('should be comparable', () {
        expect(LogLevel.debug, equals(LogLevel.debug));
        expect(LogLevel.debug, isNot(equals(LogLevel.info)));
      });
    });

    group('MetricType Tests', () {
      test('should have correct values', () {
        expect(MetricType.counter.index, 0);
        expect(MetricType.gauge.index, 1);
        expect(MetricType.histogram.index, 2);
        expect(MetricType.timer.index, 3);
      });
    });

    group('LogEvent Tests', () {
      test('should create with all properties', () {
        final timestamp = DateTime.now();
        final context = {'key': 'value'};

        final event = LogEvent(
          timestamp: timestamp,
          level: LogLevel.error,
          message: 'Test message',
          context: context,
          source: 'test',
        );

        expect(event.timestamp, timestamp);
        expect(event.level, LogLevel.error);
        expect(event.message, 'Test message');
        expect(event.context, context);
        expect(event.source, 'test');
      });

      test('should create with minimal properties', () {
        final event = LogEvent(
          timestamp: DateTime.now(),
          level: LogLevel.info,
          message: 'Test message',
        );

        expect(event.level, LogLevel.info);
        expect(event.message, 'Test message');
        expect(event.context, isNull);
        expect(event.source, isNull);
      });

      test('should serialize to JSON', () {
        final timestamp = DateTime(2023, 1, 1, 12, 0, 0);
        final event = LogEvent(
          timestamp: timestamp,
          level: LogLevel.error,
          message: 'Test message',
          context: {'key': 'value'},
          source: 'test',
        );

        final json = event.toJson();

        expect(json['timestamp'], '2023-01-01T12:00:00.000');
        expect(json['level'], 'LogLevel.error');
        expect(json['message'], 'Test message');
        expect(json['context'], {'key': 'value'});
        expect(json['source'], 'test');
      });
    });

    group('MetricEvent Tests', () {
      test('should create with all properties', () {
        final timestamp = DateTime.now();
        final labels = {'method': 'GET', 'status': '200'};

        final event = MetricEvent(
          timestamp: timestamp,
          type: MetricType.counter,
          name: 'requests_total',
          value: 1.0,
          labels: labels,
        );

        expect(event.timestamp, timestamp);
        expect(event.name, 'requests_total');
        expect(event.value, 1.0);
        expect(event.type, MetricType.counter);
        expect(event.labels, labels);
      });

      test('should create with minimal properties', () {
        final event = MetricEvent(
          timestamp: DateTime.now(),
          type: MetricType.counter,
          name: 'requests_total',
          value: 1.0,
        );

        expect(event.name, 'requests_total');
        expect(event.value, 1.0);
        expect(event.type, MetricType.counter);
        expect(event.labels, isNull);
      });

      test('should serialize to JSON', () {
        final timestamp = DateTime(2023, 1, 1, 12, 0, 0);
        final event = MetricEvent(
          timestamp: timestamp,
          type: MetricType.counter,
          name: 'requests_total',
          value: 1.0,
          labels: {'method': 'GET'},
        );

        final json = event.toJson();

        expect(json['timestamp'], '2023-01-01T12:00:00.000');
        expect(json['type'], 'MetricType.counter');
        expect(json['name'], 'requests_total');
        expect(json['value'], 1.0);
        expect(json['labels'], {'method': 'GET'});
      });
    });

    group('TimerMetric Tests', () {
      test('should measure elapsed time', () async {
        final observability = SimpleObservability();
        final timer = observability.startTimer('test_operation');

        await Future.delayed(Duration(milliseconds: 50));
        expect(() => timer.stop(), returnsNormally);
      });

      test('should handle multiple timers', () async {
        final observability = SimpleObservability();
        final timer1 = observability.startTimer('operation1');
        final timer2 = observability.startTimer('operation2');

        await Future.delayed(Duration(milliseconds: 10));
        expect(() => timer1.stop(), returnsNormally);

        await Future.delayed(Duration(milliseconds: 10));
        expect(() => timer2.stop(), returnsNormally);
      });
    });
  });
}
