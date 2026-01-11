import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

/// Represents a WebSocket Message (Send or Receive)
class WebSocketLog {
  final String id;
  final String connectionId;
  final DateTime timestamp;
  final String message;
  final bool isSent; // true = sent, false = received

  WebSocketLog({
    required this.id,
    required this.connectionId,
    required this.timestamp,
    required this.message,
    required this.isSent,
  });
}

/// Represents an active WebSocket Connection
class WebSocketConnection {
  final String id;
  final String url;
  final WebSocketChannel channel;
  final StreamController<dynamic> _streamController;
  bool isConnected;

  WebSocketConnection({
    required this.id,
    required this.url,
    required this.channel,
  })  : _streamController = StreamController.broadcast(),
        isConnected = true {
    // Pipe channel stream to our controller to allow multiple listeners
    channel.stream.listen(
      (data) {
        _streamController.add(data);
      },
      onDone: () {
        isConnected = false;
        _streamController.close();
      },
      onError: (error) {
        isConnected = false;
        _streamController.addError(error);
      },
    );
  }

  Stream<dynamic> get stream => _streamController.stream;

  void close() {
    isConnected = false;
    channel.sink.close();
  }
}

class WebSocketManager {
  final Map<String, WebSocketConnection> _connections = {};
  final StreamController<WebSocketLog> _logController = StreamController.broadcast();

  // Expose logs stream
  Stream<WebSocketLog> get logStream => _logController.stream;

  /// Connect to a WebSocket URL
  /// Returns connectionId
  Future<String> connect(String url, {Map<String, dynamic>? headers}) async {
    try {
      final uri = Uri.parse(url);
      final channel = WebSocketChannel.connect(uri);
      
      // Wait for connection ready (optional, but good for verification)
      await channel.ready;

      final connectionId = const Uuid().v4();
      final connection = WebSocketConnection(
        id: connectionId,
        url: url,
        channel: channel,
      );

      _connections[connectionId] = connection;

      // Listen for incoming messages to log
      connection.stream.listen(
        (data) {
          _log(connectionId, data.toString(), isSent: false);
        },
        onError: (e) {
           _log(connectionId, 'Error: $e', isSent: false);
        },
        onDone: () {
           _log(connectionId, 'Connection Closed', isSent: false);
           _connections.remove(connectionId);
        }
      );

      _log(connectionId, 'Connected to $url', isSent: true);
      return connectionId;
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  /// Send message to a specific connection
  void send(String connectionId, String message) {
    final connection = _connections[connectionId];
    if (connection == null || !connection.isConnected) {
      throw Exception('Connection not found or closed: $connectionId');
    }

    try {
      connection.channel.sink.add(message);
      _log(connectionId, message, isSent: true);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Close a connection
  void disconnect(String connectionId) {
    final connection = _connections[connectionId];
    if (connection != null) {
      connection.close();
      _connections.remove(connectionId);
      _log(connectionId, 'Disconnected by user', isSent: true);
    }
  }
  
  /// Get active connection IDs
  List<String> getActiveConnections() => _connections.keys.toList();
  
  /// Get connection by ID (internal use mainly)
  WebSocketConnection? getConnection(String id) => _connections[id];

  void _log(String connectionId, String message, {required bool isSent}) {
    _logController.add(WebSocketLog(
      id: const Uuid().v4(),
      connectionId: connectionId,
      timestamp: DateTime.now(),
      message: message,
      isSent: isSent,
    ));
  }
  
  void dispose() {
    for (var conn in _connections.values) {
      conn.close();
    }
    _connections.clear();
    _logController.close();
  }
}

final webSocketManagerProvider = Provider<WebSocketManager>((ref) {
  final manager = WebSocketManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final webSocketLogProvider = StreamProvider<WebSocketLog>((ref) {
  final manager = ref.watch(webSocketManagerProvider);
  return manager.logStream;
});
