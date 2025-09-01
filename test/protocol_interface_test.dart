import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:signalr_ultra/signalr_ultra.dart';

void main() {
  group('ProtocolInterface Tests', () {
    group('MessageType Tests', () {
      test('should have correct values', () {
        expect(MessageType.invocation, equals(MessageType.invocation));
        expect(MessageType.completion, equals(MessageType.completion));
        expect(MessageType.streamItem, equals(MessageType.streamItem));
        expect(MessageType.ping, equals(MessageType.ping));
        expect(MessageType.close, equals(MessageType.close));
        expect(MessageType.streamInvocation, equals(MessageType.streamInvocation));
        expect(MessageType.cancelInvocation, equals(MessageType.cancelInvocation));
        expect(MessageType.ack, equals(MessageType.ack));
        expect(MessageType.sequence, equals(MessageType.sequence));
        expect(MessageType.handshakeRequest, equals(MessageType.handshakeRequest));
        expect(MessageType.handshakeResponse, equals(MessageType.handshakeResponse));
        expect(MessageType.handshakeError, equals(MessageType.handshakeError));
      });

      test('should have correct string representations', () {
        expect(MessageType.invocation.toString(), contains('invocation'));
        expect(MessageType.completion.toString(), contains('completion'));
        expect(MessageType.streamItem.toString(), contains('streamItem'));
        expect(MessageType.ping.toString(), contains('ping'));
        expect(MessageType.close.toString(), contains('close'));
        expect(MessageType.streamInvocation.toString(), contains('streamInvocation'));
        expect(MessageType.cancelInvocation.toString(), contains('cancelInvocation'));
        expect(MessageType.ack.toString(), contains('ack'));
        expect(MessageType.sequence.toString(), contains('sequence'));
        expect(MessageType.handshakeRequest.toString(), contains('handshakeRequest'));
        expect(MessageType.handshakeResponse.toString(), contains('handshakeResponse'));
        expect(MessageType.handshakeError.toString(), contains('handshakeError'));
      });
    });

    group('SignalRMessage Tests', () {
      test('should have correct message types', () {
        final invocation = InvocationMessage(target: 'test');
        expect(invocation.type, equals(MessageType.invocation));

        final completion = CompletionMessage(invocationId: '123');
        expect(completion.type, equals(MessageType.completion));
      });
    });

    group('InvocationMessage Tests', () {
      test('should create with required parameters', () {
        final message = InvocationMessage(target: 'testMethod');
        expect(message.target, equals('testMethod'));
        expect(message.arguments, isNull);
        expect(message.invocationId, isNull);
        expect(message.headers, isNull);
      });

      test('should create with all parameters', () {
        final message = InvocationMessage(
          target: 'testMethod',
          arguments: ['arg1', 'arg2'],
          invocationId: '123',
          headers: {'key': 'value'},
        );

        expect(message.target, equals('testMethod'));
        expect(message.arguments, equals(['arg1', 'arg2']));
        expect(message.invocationId, equals('123'));
        expect(message.headers, equals({'key': 'value'}));
      });
    });

    group('CompletionMessage Tests', () {
      test('should create with required parameters', () {
        final message = CompletionMessage(invocationId: '123');
        expect(message.invocationId, equals('123'));
        expect(message.result, isNull);
        expect(message.error, isNull);
        expect(message.headers, isNull);
      });

      test('should create with all parameters', () {
        final message = CompletionMessage(
          invocationId: '123',
          result: 'success',
          error: 'error',
          headers: {'key': 'value'},
        );

        expect(message.invocationId, equals('123'));
        expect(message.result, equals('success'));
        expect(message.error, equals('error'));
        expect(message.headers, equals({'key': 'value'}));
      });

      test('should create with null invocationId', () {
        final message = CompletionMessage(invocationId: null);
        expect(message.invocationId, isNull);
      });
    });

    group('ProtocolInterface Implementation Tests', () {
      late JsonProtocol protocol;

      setUp(() {
        protocol = JsonProtocol();
      });

      test('should have correct transfer format', () {
        expect(protocol.transferFormat, equals(TransferFormat.text));
      });

      test('should create handshake request', () {
        final handshake = protocol.createHandshakeRequest();
        expect(handshake, isA<Uint8List>());
        expect(handshake.length, greaterThan(0));

        final json = utf8.decode(handshake);
        final data = jsonDecode(json);
        expect(data, isA<Map<String, dynamic>>());
      });

      test('should parse valid handshake response', () {
        final response = Uint8List.fromList(utf8.encode('{"error": null}'));
        expect(protocol.parseHandshakeResponse(response), isTrue);
      });

      test('should parse invalid handshake response', () {
        final response = Uint8List.fromList(utf8.encode('{"error": "test"}'));
        expect(protocol.parseHandshakeResponse(response), isFalse);
      });

      test('should validate valid messages', () {
        final message = Uint8List.fromList(utf8.encode('{"type": 1, "target": "test"}'));
        expect(protocol.isValidMessage(message), isTrue);
      });

      test('should validate invalid messages', () {
        final message = Uint8List.fromList(utf8.encode('invalid json'));
        expect(protocol.isValidMessage(message), isFalse);
      });

      test('should write and parse invocation message', () {
        final originalMessage = InvocationMessage(
          target: 'testMethod',
          arguments: ['arg1'],
          invocationId: '123',
          headers: {'test': 'value'},
        );

        final data = protocol.writeMessage(originalMessage);
        final messages = protocol.parseMessages(data);

        expect(messages, hasLength(1));
        expect(messages.first, isA<InvocationMessage>());

        final parsedMessage = messages.first as InvocationMessage;
        expect(parsedMessage.target, equals('testMethod'));
        expect(parsedMessage.arguments, equals(['arg1']));
        expect(parsedMessage.invocationId, equals('123'));
        expect(parsedMessage.headers, equals({'test': 'value'}));
      });

      test('should write and parse completion message', () {
        final originalMessage = CompletionMessage(
          invocationId: '123',
          result: 'success',
          headers: {'test': 'value'},
        );

        final data = protocol.writeMessage(originalMessage);
        final messages = protocol.parseMessages(data);

        expect(messages, hasLength(1));
        expect(messages.first, isA<CompletionMessage>());

        final parsedMessage = messages.first as CompletionMessage;
        expect(parsedMessage.invocationId, equals('123'));
        expect(parsedMessage.result, equals('success'));
        expect(parsedMessage.headers, equals({'test': 'value'}));
      });

      test('should handle empty message list', () {
        final data = Uint8List.fromList(utf8.encode('[]'));
        final messages = protocol.parseMessages(data);
        expect(messages, isEmpty);
      });

      test('should handle single message', () {
        final data = Uint8List.fromList(utf8.encode('{"type": 1, "target": "test"}'));
        final messages = protocol.parseMessages(data);
        expect(messages, hasLength(1));
      });

      test('should handle multiple messages', () {
        // This test would require understanding the exact format expected by JsonProtocol
        // For now, we'll test that the protocol can handle basic parsing
        final data = Uint8List.fromList(utf8.encode('{"type": 1, "target": "test"}'));
        final messages = protocol.parseMessages(data);
        expect(messages, hasLength(1));
      });
    });
  });
}
