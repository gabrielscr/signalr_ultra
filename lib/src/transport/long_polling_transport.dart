import 'dart:async';
import 'dart:convert';

import '../core/domain/interfaces/transport_interface.dart';
import '../core/logging/signalr_logger.dart';
import '../utils/platform_compatibility.dart';

/// Long Polling transport implementation for SignalR
/// Uses HTTP requests to simulate real-time communication
class LongPollingTransport implements TransportInterface {
  LongPollingTransport({
    required SignalRLogger logger,
    Map<String, String>? headers,
    Duration? timeout,
  })  : _logger = logger,
        _headers = headers ?? {};

  final SignalRLogger _logger;
  final Map<String, String> _headers;

  HttpClient? _client;
  Timer? _pollingTimer;
  final StreamController<dynamic> _dataController = StreamController<dynamic>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  bool _isConnected = false;
  bool _isPolling = false;
  String? _currentUrl;
  String? _connectionId;
  String? _connectionToken;

  @override
  TransportType get type => TransportType.longPolling;

  @override
  List<TransferFormat> get supportedFormats => [TransferFormat.text];

  @override
  Future<void> connect({
    required String url,
    Map<String, String>? headers,
    TransferFormat format = TransferFormat.text,
  }) async {
    if (_isConnected) {
      throw Exception('Long polling transport already connected');
    }

    if (format != TransferFormat.text) {
      throw Exception('Long polling transport only supports text format');
    }

    _currentUrl = url;
    _logger.transport('Connecting to long polling endpoint',
        type: 'LONGPOLLING', operation: 'CONNECT', data: {'url': url});

    try {
      _client = await PlatformCompatibility.createHttpClient();

      // Perform SignalR negotiation to get connection details
      await _negotiate(url, headers);

      _isConnected = true;
      _connectionController.add(true);

      _logger.transport('Long polling connection established', type: 'LONGPOLLING', operation: 'CONNECTED');

      // Start polling for messages
      _startPolling();
    } catch (e) {
      _logger.error('Long polling connection failed', exception: e);
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _logger.transport('Disconnecting long polling transport', type: 'LONGPOLLING', operation: 'DISCONNECT');

    _isConnected = false;
    _isPolling = false;
    _connectionController.add(false);

    _pollingTimer?.cancel();
    _pollingTimer = null;

    _client?.close();
    _client = null;

    _logger.transport('Long polling transport disconnected', type: 'LONGPOLLING', operation: 'DISCONNECTED');
  }

  @override
  Future<void> send(dynamic data) async {
    if (!_isConnected) {
      throw Exception('Long polling transport not connected');
    }

    try {
      final response = await _sendViaHttp(data.toString());
      _logger.transport('Long polling send completed',
          type: 'LONGPOLLING', operation: 'SEND', data: {'response': response});
    } catch (e) {
      _logger.error('Long polling send failed', exception: e);
      rethrow;
    }
  }

  @override
  Stream<dynamic> get dataStream => _dataController.stream;

  @override
  Stream<bool> get connectionStateStream => _connectionController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  String? get url => _currentUrl;

  @override
  Map<String, String> get headers => Map.from(_headers);

  /// Performs SignalR negotiation to establish connection parameters
  Future<void> _negotiate(String url, Map<String, String>? headers) async {
    final negotiateUrl = '$url/negotiate';

    try {
      final request = await _client!.postUrl(Uri.parse(negotiateUrl));

      // Set headers
      request.headers['Content-Type'] = 'application/json';
      for (final entry in _headers.entries) {
        request.headers[entry.key] = entry.value;
      }

      if (headers != null) {
        for (final entry in headers.entries) {
          request.headers[entry.key] = entry.value;
        }
      }

      final response = await request.close();
      final responseData = await response.bodyText.join();

      if (response.statusCode != 200) {
        throw Exception('Negotiation failed with status: ${response.statusCode}');
      }

      final negotiateResponse = jsonDecode(responseData);
      _connectionId = negotiateResponse['connectionId'];
      _connectionToken = negotiateResponse['connectionToken'];

      _logger.transport('Negotiation completed', type: 'LONGPOLLING', operation: 'NEGOTIATE', data: {
        'connectionId': _connectionId,
        'connectionToken': _connectionToken,
      });
    } catch (e) {
      _logger.error('Negotiation failed', exception: e);
      rethrow;
    }
  }

  /// Starts the polling loop for receiving messages
  void _startPolling() {
    if (_isPolling) return;

    _isPolling = true;
    _pollForMessages();
  }

  /// Polls for messages from the server using long polling technique
  Future<void> _pollForMessages() async {
    if (!_isPolling || !_isConnected) return;

    try {
      final pollUrl = '$_currentUrl/poll?connectionId=$_connectionId';

      final request = await _client!.getUrl(Uri.parse(pollUrl));

      // Set headers
      request.headers['Accept'] = 'application/json';
      for (final entry in _headers.entries) {
        request.headers[entry.key] = entry.value;
      }

      final response = await request.close();

      if (response.statusCode == 200) {
        final responseData = await response.bodyText.join();

        if (responseData.isNotEmpty) {
          try {
            final messages = jsonDecode(responseData);
            if (messages is List) {
              messages.forEach(_dataController.add);
            } else {
              _dataController.add(messages);
            }

            _logger.transport('Long polling messages received',
                type: 'LONGPOLLING', operation: 'RECEIVE', data: {'count': messages is List ? messages.length : 1});
          } catch (e) {
            _logger.error('Failed to parse polling response', exception: e);
          }
        }

        // Continue polling
        _pollingTimer = Timer(const Duration(milliseconds: 100), () {
          _pollForMessages();
        });
      } else {
        _logger.error('Polling failed with status: ${response.statusCode}');
        _isPolling = false;
        _connectionController.add(false);
      }
    } catch (e) {
      _logger.error('Polling error', exception: e);
      _isPolling = false;
      _connectionController.add(false);
    }
  }

  /// Sends data via HTTP POST to the SignalR hub
  Future<String> _sendViaHttp(String data) async {
    final sendUrl = '$_currentUrl/send?connectionId=$_connectionId';

    final request = await _client!.postUrl(Uri.parse(sendUrl));

    // Set headers
    request.headers['Content-Type'] = 'application/json';
    for (final entry in _headers.entries) {
      request.headers[entry.key] = entry.value;
    }

    request.addString(data);
    final response = await request.close();
    final responseData = await response.bodyText.join();

    if (response.statusCode != 200) {
      throw Exception('Send failed with status: ${response.statusCode}');
    }

    return responseData;
  }
}
