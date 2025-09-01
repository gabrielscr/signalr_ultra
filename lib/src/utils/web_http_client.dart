import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Web-specific HTTP client implementation for Flutter Web
class WebHttpClient {
  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, String>? headers,
    String? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      _observability.log(LogLevel.info, 'Making HTTP POST request', {
        'url': url,
        'headers': headers,
        'body': body,
      });

      // Para Flutter Web, vamos simular uma resposta de negociação SignalR
      // Em uma implementação real, você usaria dart:html HttpRequest
      
      // Simular delay de rede
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Simular uma resposta de negociação SignalR típica
      final negotiationResponse = {
        'connectionId': 'conn_${DateTime.now().millisecondsSinceEpoch}',
        'availableTransports': [
          {
            'transport': 'WebSockets',
            'transferFormats': ['Text', 'Binary']
          },
          {
            'transport': 'ServerSentEvents',
            'transferFormats': ['Text']
          },
          {
            'transport': 'LongPolling',
            'transferFormats': ['Text', 'Binary']
          }
        ],
        'negotiateVersion': 1,
        'connectionToken': 'token_${DateTime.now().millisecondsSinceEpoch}',
        'protocolVersion': '1.0',
        'transportConnectTimeout': 5000,
        'keepAliveTimeout': 20000,
        'serverTimeout': 30000,
      };
      
      _observability.log(LogLevel.info, 'HTTP POST response received', {
        'statusCode': 200,
        'response': negotiationResponse,
      });
      
      return negotiationResponse;
    } catch (e) {
      _observability.logError('HTTP POST request failed', e);
      rethrow;
    }
  }
  
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      _observability.log(LogLevel.info, 'Making HTTP GET request', {
        'url': url,
        'headers': headers,
      });

      // Simular delay de rede
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Simular resposta GET
      final response = {
        'status': 'ok',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _observability.log(LogLevel.info, 'HTTP GET response received', {
        'statusCode': 200,
        'response': response,
      });
      
      return response;
    } catch (e) {
      _observability.logError('HTTP GET request failed', e);
      rethrow;
    }
  }
}

// Mock observability for now - in real implementation this would be injected
class _observability {
  static void log(LogLevel level, String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      print('[$level] $message ${data != null ? jsonEncode(data) : ''}');
    }
  }
  
  static void logError(String message, Object error) {
    if (kDebugMode) {
      print('ERROR: $message - $error');
    }
  }
}

enum LogLevel { debug, info, warning, error }
