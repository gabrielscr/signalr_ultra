import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:signalr_ultra/signalr_ultra.dart';

void main() {
  group('SignalRBuilder Tests', () {
    test('should create with default configuration', () {
      final builder = SignalRBuilder();

      expect(builder, isNotNull);
    });

    test('should set URL', () {
      final url = 'https://test.com/hub';
      final builder = SignalRBuilder().withUrl(url);

      final client = builder.build();
      expect(client, isA<SignalRClient>());
    });

    test('should set headers', () {
      final headers = {'Authorization': 'Bearer token'};
      final builder = SignalRBuilder()
        ..withHeaders(headers)
        ..withUrl('https://test.com/hub');

      final client = builder.build();
      expect(client, isA<SignalRClient>());
    });

    test('should set transport type', () {
      final builder = SignalRBuilder()
        ..withTransport(TransportType.webSocket)
        ..withUrl('https://test.com/hub');

      final client = builder.build();
      expect(client, isA<SignalRClient>());
    });

    test('should set timeout', () {
      final timeout = Duration(seconds: 60);
      final builder = SignalRBuilder()
        ..withTimeout(timeout)
        ..withUrl('https://test.com/hub');

      final client = builder.build();
      expect(client, isA<SignalRClient>());
    });

    test('should set log level', () {
      final builder = SignalRBuilder()
        ..withLogLevel(Level.debug)
        ..withUrl('https://test.com/hub');

      final client = builder.build();
      expect(client, isA<SignalRClient>());
    });

    test('should set log prefix', () {
      final builder = SignalRBuilder()
        ..withLogPrefix('TEST')
        ..withUrl('https://test.com/hub');

      final client = builder.build();
      expect(client, isA<SignalRClient>());
    });

    test('should set failure threshold', () {
      final builder = SignalRBuilder()
        ..withFailureThreshold(3)
        ..withUrl('https://test.com/hub');

      final client = builder.build();
      expect(client, isA<SignalRClient>());
    });

    test('should set reset timeout', () {
      final builder = SignalRBuilder()
        ..withResetTimeout(Duration(seconds: 10))
        ..withUrl('https://test.com/hub');

      final client = builder.build();
      expect(client, isA<SignalRClient>());
    });

    test('should build SignalRClient with all custom components', () {
      final headers = {'Authorization': 'Bearer token'};
      final timeout = Duration(seconds: 60);

      final builder = SignalRBuilder();
      builder.withUrl('https://test.com/hub');
      builder.withTransport(TransportType.webSocket);
      builder.withHeaders(headers);
      builder.withTimeout(timeout);
      builder.withLogLevel(Level.debug);
      builder.withLogPrefix('TEST');
      builder.withFailureThreshold(3);
      builder.withResetTimeout(Duration(seconds: 10));
      
      final client = builder.build();

      expect(client, isA<SignalRClient>());
    });

    test('should handle method chaining', () {
      final builder = SignalRBuilder();
      builder.withUrl('https://test.com/hub');
      builder.withTransport(TransportType.webSocket);
      builder.withHeaders({'test': 'value'});
      builder.withTimeout(Duration(seconds: 45));
      builder.withLogLevel(Level.info);
      builder.withLogPrefix('CHAIN');
      builder.withFailureThreshold(5);
      builder.withResetTimeout(Duration(seconds: 30));
      
      final client = builder.build();

      expect(client, isA<SignalRClient>());
    });

    test('should throw error when URL is not provided', () {
      final builder = SignalRBuilder();
      expect(() => builder.build(), throwsA(isA<ArgumentError>()));
    });

    test('should support all transport types', () {
      final transportTypes = [
        TransportType.webSocket,
        TransportType.serverSentEvents,
        TransportType.longPolling,
        TransportType.auto,
      ];

      for (final type in transportTypes) {
        final builder = SignalRBuilder();
        builder.withUrl('https://test.com/hub');
        builder.withTransport(type);
        final client = builder.build();

        expect(client, isA<SignalRClient>());
      }
    });
  });

  group('ConnectionBuilder Tests', () {
    test('should create with default configuration', () {
      final builder = ConnectionBuilder();

      expect(builder, isNotNull);
    });

    test('should set URL', () {
      final url = 'https://test.com/hub';
      final builder = ConnectionBuilder().withUrl(url);

      expect(() => builder.build(), throwsA(isA<UnimplementedError>()));
    });

    test('should set headers', () {
      final headers = {'Authorization': 'Bearer token'};
      final builder = ConnectionBuilder().withHeaders(headers);

      expect(() => builder.build(), throwsA(isA<ArgumentError>()));
    });

    test('should set timeout', () {
      final timeout = Duration(seconds: 60);
      final builder = ConnectionBuilder().withTimeout(timeout);

      expect(() => builder.build(), throwsA(isA<ArgumentError>()));
    });

    test('should set custom transport', () {
      final transport = SSETransport(
        logger: SignalRLogger(),
        headers: {},
        timeout: Duration(seconds: 30),
      );

      final builder = ConnectionBuilder()
        ..withUrl('https://test.com/hub')
        ..withTransport(transport);

      expect(() => builder.build(), throwsA(isA<UnimplementedError>()));
    });

    test('should set custom protocol', () {
      final protocol = JsonProtocol();
      final builder = ConnectionBuilder()
        ..withUrl('https://test.com/hub')
        ..withProtocol(protocol);

      expect(() => builder.build(), throwsA(isA<UnimplementedError>()));
    });

    test('should set custom circuit breaker', () {
      final circuitBreaker = SimpleCircuitBreaker();
      final builder = ConnectionBuilder()
        ..withUrl('https://test.com/hub')
        ..withCircuitBreaker(circuitBreaker);

      expect(() => builder.build(), throwsA(isA<UnimplementedError>()));
    });

    test('should set custom observability', () {
      final observability = SimpleObservability();
      final builder = ConnectionBuilder()
        ..withUrl('https://test.com/hub')
        ..withObservability(observability);

      expect(() => builder.build(), throwsA(isA<UnimplementedError>()));
    });

    test('should throw error when URL is not provided', () {
      final builder = ConnectionBuilder();
      expect(() => builder.build(), throwsA(isA<ArgumentError>()));
    });

    test('should handle method chaining', () {
      final builder = ConnectionBuilder();
      builder.withUrl('https://test.com/hub');
      builder.withHeaders({'Authorization': 'Bearer token'});
      builder.withTimeout(Duration(seconds: 45));

      expect(() => builder.build(), throwsA(isA<UnimplementedError>()));
    });
  });

  group('TransportBuilder Tests', () {
    test('should create with default configuration', () {
      final builder = TransportBuilder();

      expect(builder, isNotNull);
    });

    test('should set transport type', () {
      final builder = TransportBuilder().withType(TransportType.serverSentEvents);

      final transport = builder.build();
      expect(transport, isA<TransportInterface>());
    });

    test('should set connect timeout', () {
      final timeout = Duration(seconds: 60);
      final builder = TransportBuilder().withConnectTimeout(timeout);

      final transport = builder.build();
      expect(transport, isA<TransportInterface>());
    });

    test('should set custom headers', () {
      final headers = {'Authorization': 'Bearer token'};
      final builder = TransportBuilder().withCustomHeaders(headers);

      final transport = builder.build();
      expect(transport, isA<TransportInterface>());
    });

    test('should build transport configuration', () {
      final headers = {'Authorization': 'Bearer token'};
      final timeout = Duration(seconds: 60);

      final builder = TransportBuilder();
      builder.withType(TransportType.webSocket);
      builder.withCustomHeaders(headers);
      builder.withConnectTimeout(timeout);
      final transport = builder.build();

      expect(transport, isA<TransportInterface>());
    });

    test('should handle method chaining', () {
      final builder = TransportBuilder();
      builder.withType(TransportType.longPolling);
      builder.withCustomHeaders({'Authorization': 'Bearer token'});
      builder.withConnectTimeout(Duration(seconds: 45));
      final transport = builder.build();

      expect(transport, isA<TransportInterface>());
    });

    test('should support all transport types', () {
      final types = [
        TransportType.webSocket,
        TransportType.serverSentEvents,
        TransportType.longPolling,
      ];

      for (final type in types) {
        final transport = TransportBuilder().withType(type).build();
        expect(transport, isA<TransportInterface>());
      }
    });

    test('should support static factory methods', () {
      final websocketTransport = TransportBuilder.websocket().build();
      final sseTransport = TransportBuilder.serverSentEvents().build();
      final longPollingTransport = TransportBuilder.longPolling().build();

      expect(websocketTransport, isA<TransportInterface>());
      expect(sseTransport, isA<TransportInterface>());
      expect(longPollingTransport, isA<TransportInterface>());
    });

    test('should merge custom headers correctly', () {
      final initialHeaders = {'Content-Type': 'application/json'};
      final additionalHeaders = {'Authorization': 'Bearer token'};

      final builder = TransportBuilder();
      builder.withCustomHeaders(initialHeaders);
      builder.withCustomHeaders(additionalHeaders);
      final transport = builder.build();

      expect(transport, isA<TransportInterface>());
    });

    test('should override custom headers', () {
      final builder = TransportBuilder();
      builder.withCustomHeaders({'Content-Type': 'application/json'});
      builder.withCustomHeaders({'Content-Type': 'text/plain'});
      final transport = builder.build();

      expect(transport, isA<TransportInterface>());
    });
  });

  group('JsonProtocol Tests', () {
    test('should have correct properties', () {
      final protocol = JsonProtocol();

      expect(protocol.name, 'json');
      expect(protocol.version, 1);
      expect(protocol.transferFormat, TransferFormat.text);
    });

    test('should write and parse messages', () {
      final protocol = JsonProtocol();
      final message = InvocationMessage(
        target: 'testMethod',
        arguments: ['arg1', 'arg2'],
        invocationId: '123',
      );

      final data = protocol.writeMessage(message);
      expect(data, isA<Uint8List>());

      final messages = protocol.parseMessages(data);
      expect(messages, hasLength(1));
      expect(messages.first, isA<InvocationMessage>());
    });

    test('should create handshake request', () {
      final protocol = JsonProtocol();
      final handshake = protocol.createHandshakeRequest();

      expect(handshake, isA<Uint8List>());
      expect(handshake.length, greaterThan(0));
    });

    test('should parse handshake response', () {
      final protocol = JsonProtocol();
      
      // Valid response
      final validResponse = Uint8List.fromList(utf8.encode('{"error": null}'));
      expect(protocol.parseHandshakeResponse(validResponse), isTrue);

      // Invalid response
      final invalidResponse = Uint8List.fromList(utf8.encode('{"error": "test"}'));
      expect(protocol.parseHandshakeResponse(invalidResponse), isFalse);
    });

    test('should validate messages', () {
      final protocol = JsonProtocol();
      
      // Valid JSON
      final validMessage = Uint8List.fromList(utf8.encode('{"type": 1, "target": "test"}'));
      expect(protocol.isValidMessage(validMessage), isTrue);

      // Invalid JSON
      final invalidMessage = Uint8List.fromList(utf8.encode('invalid json'));
      expect(protocol.isValidMessage(invalidMessage), isFalse);
    });

    test('should convert messages to JSON', () {
      final protocol = JsonProtocol();
      final message = InvocationMessage(
        target: 'testMethod',
        arguments: ['arg1'],
        invocationId: '123',
        headers: {'test': 'value'},
      );

      final data = protocol.writeMessage(message);
      final json = utf8.decode(data);
      final map = jsonDecode(json);

      expect(map['type'], 1);
      expect(map['target'], 'testMethod');
      expect(map['arguments'], ['arg1']);
      expect(map['invocationId'], '123');
      expect(map['headers']['test'], 'value');
    });

    test('should convert JSON to messages', () {
      final protocol = JsonProtocol();
      final json = '{"type": 1, "target": "testMethod", "arguments": ["arg1"], "invocationId": "123"}';
      final data = Uint8List.fromList(utf8.encode(json));

      final messages = protocol.parseMessages(data);
      expect(messages, hasLength(1));

      final message = messages.first as InvocationMessage;
      expect(message.target, 'testMethod');
      expect(message.arguments, ['arg1']);
      expect(message.invocationId, '123');
    });

    test('should handle completion messages', () {
      final protocol = JsonProtocol();
      final message = CompletionMessage(
        invocationId: '123',
        result: 'success',
        headers: {'test': 'value'},
      );

      final data = protocol.writeMessage(message);
      final json = utf8.decode(data);
      final map = jsonDecode(json);

      expect(map['type'], 3);
      expect(map['invocationId'], '123');
      expect(map['result'], 'success');
      expect(map['headers']['test'], 'value');
    });

    test('should handle unknown message types', () {
      final protocol = JsonProtocol();
      final json = '{"type": 999, "target": "unknown"}';
      final data = Uint8List.fromList(utf8.encode(json));

      expect(() => protocol.parseMessages(data), returnsNormally);
    });
  });
}
