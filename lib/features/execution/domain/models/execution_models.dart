enum NodeStatus {
  idle,
  running,
  success,
  failure,
}

class NodeRunResult {
  final String nodeId;
  final NodeStatus status;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? statusCode;
  final Map<String, String>? responseHeaders;
  final dynamic? responseBody;
  final String? errorMessage;

  const NodeRunResult({
    required this.nodeId,
    this.status = NodeStatus.idle,
    this.startedAt,
    this.finishedAt,
    this.statusCode,
    this.responseHeaders,
    this.responseBody,
    this.errorMessage,
  });

  NodeRunResult copyWith({
    NodeStatus? status,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? statusCode,
    Map<String, String>? responseHeaders,
    dynamic? responseBody,
    String? errorMessage,
  }) {
    return NodeRunResult(
      nodeId: nodeId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      statusCode: statusCode ?? this.statusCode,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
