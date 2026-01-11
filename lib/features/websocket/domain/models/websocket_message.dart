enum WebSocketMessageDirection { sent, received, system }

class WebSocketMessage {
  final String id;
  final WebSocketMessageDirection direction;
  final DateTime timestamp;
  final String payloadText;
  final int sizeBytes;
  final dynamic parsedJson; // Optional

  WebSocketMessage({
    required this.id,
    required this.direction,
    required this.timestamp,
    required this.payloadText,
    required this.sizeBytes,
    this.parsedJson,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'direction': direction.name,
    'timestamp': timestamp.toIso8601String(),
    'payloadText': payloadText,
    'sizeBytes': sizeBytes,
    'parsedJson': parsedJson, // Ensure this is JSON encodable if used
  };

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) => WebSocketMessage(
    id: json['id'],
    direction: WebSocketMessageDirection.values.byName(json['direction']),
    timestamp: DateTime.parse(json['timestamp']),
    payloadText: json['payloadText'],
    sizeBytes: json['sizeBytes'],
    parsedJson: json['parsedJson'],
  );
}

enum WebSocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class WebSocketSessionState {
  final WebSocketConnectionStatus status;
  final String? lastError;
  final List<WebSocketMessage> messages;
  final int maxMessages;

  const WebSocketSessionState({
    this.status = WebSocketConnectionStatus.disconnected,
    this.lastError,
    this.messages = const [],
    this.maxMessages = 500,
  });

  WebSocketSessionState copyWith({
    WebSocketConnectionStatus? status,
    String? lastError,
    List<WebSocketMessage>? messages,
  }) {
    var newMessages = messages ?? this.messages;
    
    // Trim messages if needed
    if (newMessages.length > maxMessages) {
       // Keep latest maxMessages
       // Assuming list is sorted old -> new (append at end), remove from start (index 0)
       // Or if we prepend, remove from end.
       // Usually logs are appended.
       final overflow = newMessages.length - maxMessages;
       if (overflow > 0) {
         newMessages = newMessages.sublist(overflow);
       }
    }

    return WebSocketSessionState(
      status: status ?? this.status,
      lastError: lastError, // Nullable override logic needs care if we want to clear it.
                            // For simplicty: if passed, use it. If not, keep it.
                            // If we want to clear, pass empty string or null?
                            // copyWith convention: null means keep existing. 
                            // To clear, we need a Sentinel or clear flag. 
                            // Here we will assume status change usually clears error if connecting/connected.
      messages: newMessages,
    );
  }
}
