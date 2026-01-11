import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../features/websocket/domain/models/websocket_config.dart';
import '../../features/websocket/domain/models/websocket_message.dart'; // For status enum

class WebSocketService {
  WebSocketChannel? _channel;
  
  final _statusController = StreamController<WebSocketConnectionStatus>.broadcast();
  final _messageController = StreamController<dynamic>.broadcast();
  final _errorController = StreamController<dynamic>.broadcast();

  Stream<WebSocketConnectionStatus> get statusStream => _statusController.stream;
  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<dynamic> get errorStream => _errorController.stream;

  WebSocketConnectionStatus _currentStatus = WebSocketConnectionStatus.disconnected;
  WebSocketConnectionStatus get currentStatus => _currentStatus;

  Future<void> connect(WebSocketConfig config) async {
    _updateStatus(WebSocketConnectionStatus.connecting);

    try {
      if (kIsWeb && config.headers.isNotEmpty) {
         // Warning: Headers are not fully supported on Web WebSocket API
         print('WARNING: WebSocket headers are not supported on Web.');
      }

      final uri = Uri.parse(config.url);
      
      // Merge Headers
      final headers = Map<String, dynamic>.from(config.headers);
      
      Uri finalUri = uri;
      final auth = config.auth;
      if (auth.type == WebSocketAuthType.apiKey) {
         if (auth.addTo == 'query' && auth.key != null && auth.value != null) {
            final query = Map<String, String>.from(uri.queryParameters);
            query[auth.key!] = auth.value!;
            finalUri = uri.replace(queryParameters: query);
         } else if (auth.addTo == 'header' && auth.key != null && auth.value != null) {
            headers[auth.key!] = auth.value!;
         }
      } else if (auth.type == WebSocketAuthType.bearer && auth.token != null) {
          headers['Authorization'] = 'Bearer ${auth.token}';
      }

      // Connect
      _channel = WebSocketChannel.connect(finalUri); 
      await _channel!.ready;

      _updateStatus(WebSocketConnectionStatus.connected);

      _channel!.stream.listen(
        (data) {
          _messageController.add(data);
        },
        onError: (error) {
          _errorController.add(error);
           _updateStatus(WebSocketConnectionStatus.error);
        },
        onDone: () {
          _updateStatus(WebSocketConnectionStatus.disconnected);
        },
      );
    } catch (e) {
      _errorController.add(e);
      _updateStatus(WebSocketConnectionStatus.error);
      disconnect(); 
    }
  }

  void send(String text) {
    if (_channel != null && _currentStatus == WebSocketConnectionStatus.connected) {
      _channel!.sink.add(text);
    } else {
      throw Exception('WebSocket is not connected');
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    if (_currentStatus != WebSocketConnectionStatus.disconnected) {
       _updateStatus(WebSocketConnectionStatus.disconnected);
    }
  }
  
  void _updateStatus(WebSocketConnectionStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
    _errorController.close();
  }
}
