import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/websocket_config.dart';
import '../domain/models/websocket_message.dart'; // SessionState, Message, Direction, Status
import '../data/websocket_config_repository.dart';
import '../../../core/ws/websocket_service.dart';

// State Class
class WebSocketClientState {
  final String? selectedConfigId;
  final WebSocketSessionState session;

  const WebSocketClientState({
    this.selectedConfigId,
    this.session = const WebSocketSessionState(),
  });

  WebSocketClientState copyWith({
    String? selectedConfigId,
    WebSocketSessionState? session,
  }) {
    return WebSocketClientState(
      selectedConfigId: selectedConfigId ?? this.selectedConfigId,
      session: session ?? this.session,
    );
  }
}

// Service Provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

// Controller
class WebSocketClientController extends StateNotifier<WebSocketClientState> {
  final WebSocketService _service;
  final WebSocketConfigRepository _repository;

  WebSocketClientController({
    required WebSocketService service,
    required WebSocketConfigRepository repository,
  })  : _service = service,
        _repository = repository,
        super(const WebSocketClientState()) {
    _initListeners();
  }

  void _initListeners() {
    _service.statusStream.listen((status) {
      state = state.copyWith(
        session: state.session.copyWith(status: status),
      );
    });

    _service.messageStream.listen((data) {
      _addMessage(WebSocketMessageDirection.received, data);
    });

    _service.errorStream.listen((error) {
      state = state.copyWith(
        session: state.session.copyWith(
          status: WebSocketConnectionStatus.error,
          lastError: error.toString(),
        ),
      );
      _addMessage(WebSocketMessageDirection.system, 'Error: $error');
    });
  }

  void _addMessage(WebSocketMessageDirection direction, dynamic data) {
    String textPayload;
    dynamic jsonPayload;
    int sizeBytes = 0;

    if (data is String) {
      textPayload = data;
      sizeBytes = data.length;
      try {
        jsonPayload = jsonDecode(data);
      } catch (_) {
        // Not JSON
      }
    } else {
      textPayload = data.toString();
      // Calculate bytes if List<int>...
      if (data is List<int>) sizeBytes = data.length;
    }

    final message = WebSocketMessage(
      id: const Uuid().v4(),
      direction: direction,
      timestamp: DateTime.now(),
      payloadText: textPayload,
      sizeBytes: sizeBytes,
      parsedJson: jsonPayload,
    );

    state = state.copyWith(
      session: state.session.copyWith(
        messages: [...state.session.messages, message], // Logic in model handles trimming
      ),
    );
  }

  Future<void> selectConfig(String? id) async {
    // If switching config, disconnect current
    if (state.selectedConfigId != id) {
       if (_service.currentStatus == WebSocketConnectionStatus.connected) {
         _service.disconnect();
       }
       state = WebSocketClientState(selectedConfigId: id); // Reset session
    }
  }

  Future<void> connect() async {
    if (state.selectedConfigId == null) return;
    
    final config = await _repository.get(state.selectedConfigId!);
    if (config == null) {
      _addMessage(WebSocketMessageDirection.system, 'Config not found');
      return;
    }

    state = state.copyWith(
      session: state.session.copyWith(
        lastError: null, // Clear error
        status: WebSocketConnectionStatus.connecting
      )
    );

    await _service.connect(config);
  }

  void disconnect() {
    _service.disconnect();
  }

  void sendMessage(String text) {
    try {
      _service.send(text);
      _addMessage(WebSocketMessageDirection.sent, text);
    } catch (e) {
      _addMessage(WebSocketMessageDirection.system, 'Failed to send: $e');
    }
  }

  void clearLog() {
    state = state.copyWith(
      session: const WebSocketSessionState(messages: []),
    );
     // Note: This resets status too if we use const(), but we want to keep status.
     // So let's reproduce current status.
     state = state.copyWith(
       session: WebSocketSessionState(
         status: state.session.status,
         lastError: state.session.lastError,
         messages: [],
       ),
     );
  }
}

final webSocketClientProvider = StateNotifierProvider<WebSocketClientController, WebSocketClientState>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  final repo = ref.watch(webSocketConfigRepositoryProvider);
  return WebSocketClientController(service: service, repository: repo);
});
