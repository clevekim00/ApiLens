import 'metric_window_event.dart';

class NodeMetricsSnapshot {
  final String nodeId;
  final int requestCount;
  final int errorCount;
  final Map<String, int> statusCounts;
  final Map<String, int> errorTypeCounts;
  final LatencyHistogram latency;

  const NodeMetricsSnapshot({
    required this.nodeId,
    this.requestCount = 0,
    this.errorCount = 0,
    this.statusCounts = const {},
    this.errorTypeCounts = const {},
    this.latency = const LatencyHistogram(),
  });

  double get errorRate {
    if (requestCount == 0) return 0;
    return errorCount / requestCount;
  }
}

class RunMetricsSnapshot {
  final String runId;
  final int requestCount;
  final int errorCount;
  final Map<String, NodeMetricsSnapshot> nodes;
  final DateTime updatedAt;

  const RunMetricsSnapshot({
    required this.runId,
    this.requestCount = 0,
    this.errorCount = 0,
    this.nodes = const {},
    required this.updatedAt,
  });

  double get errorRate {
    if (requestCount == 0) return 0;
    return errorCount / requestCount;
  }

  NodeMetricsSnapshot? node(String nodeId) => nodes[nodeId];
}

class IngestQueueState {
  final int queueDepth;
  final Duration ingestLag;
  final int droppedEventCount;
  final int sampledEventCount;

  const IngestQueueState({
    this.queueDepth = 0,
    this.ingestLag = Duration.zero,
    this.droppedEventCount = 0,
    this.sampledEventCount = 0,
  });
}

enum BackpressureAction {
  none,
  increaseMetricWindow,
  reduceSampling,
  pauseRawEvents,
}

class BackpressureCommand {
  final String agentId;
  final BackpressureAction action;
  final int? metricWindowMs;
  final double? samplingRate;
  final String reason;

  const BackpressureCommand({
    required this.agentId,
    required this.action,
    this.metricWindowMs,
    this.samplingRate,
    this.reason = '',
  });

  bool get isNoop => action == BackpressureAction.none;
}
