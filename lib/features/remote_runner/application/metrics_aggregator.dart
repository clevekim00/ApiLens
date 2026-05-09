import '../domain/models/metric_window_event.dart';
import '../domain/models/metrics_models.dart';

class MetricsAggregator {
  final DateTime Function() _now;
  final Map<String, _MutableRunMetrics> _runs = {};

  MetricsAggregator({DateTime Function()? now}) : _now = now ?? DateTime.now;

  void add(MetricWindowEvent event) {
    final run = _runs.putIfAbsent(event.runId, () => _MutableRunMetrics());
    run.add(event);
  }

  RunMetricsSnapshot snapshot(String runId) {
    final run = _runs[runId];
    if (run == null) {
      return RunMetricsSnapshot(runId: runId, updatedAt: _now());
    }
    return run.toSnapshot(runId: runId, updatedAt: _now());
  }

  int percentileMs(String runId, String nodeId, double percentile) {
    final snapshot = this.snapshot(runId);
    final node = snapshot.nodes[nodeId];
    if (node == null) return 0;
    return percentileFromHistogram(node.latency, percentile);
  }

  static int percentileFromHistogram(
    LatencyHistogram histogram,
    double percentile,
  ) {
    if (histogram.count <= 0 || histogram.buckets.isEmpty) return 0;
    final threshold = (histogram.count * percentile).ceil();
    final sortedBuckets = histogram.buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    var seen = 0;
    for (final bucket in sortedBuckets) {
      seen += bucket.value;
      if (seen >= threshold) {
        return bucket.key;
      }
    }
    return sortedBuckets.last.key;
  }
}

class _MutableRunMetrics {
  int requestCount = 0;
  int errorCount = 0;
  final Map<String, _MutableNodeMetrics> nodes = {};

  void add(MetricWindowEvent event) {
    requestCount += event.requestCount;
    errorCount += event.errorCount;
    nodes
        .putIfAbsent(event.nodeId, () => _MutableNodeMetrics(event.nodeId))
        .add(
          event,
        );
  }

  RunMetricsSnapshot toSnapshot({
    required String runId,
    required DateTime updatedAt,
  }) {
    return RunMetricsSnapshot(
      runId: runId,
      requestCount: requestCount,
      errorCount: errorCount,
      updatedAt: updatedAt,
      nodes: nodes.map(
        (key, value) => MapEntry(key, value.toSnapshot()),
      ),
    );
  }
}

class _MutableNodeMetrics {
  final String nodeId;
  int requestCount = 0;
  int errorCount = 0;
  int minMs = 0;
  int maxMs = 0;
  int sumMs = 0;
  int latencyCount = 0;
  final Map<String, int> statusCounts = {};
  final Map<String, int> errorTypeCounts = {};
  final Map<int, int> buckets = {};

  _MutableNodeMetrics(this.nodeId);

  void add(MetricWindowEvent event) {
    requestCount += event.requestCount;
    errorCount += event.errorCount;
    _mergeStringCounts(statusCounts, event.statusCounts);
    _mergeStringCounts(errorTypeCounts, event.errorTypeCounts);
    _mergeIntCounts(buckets, event.latency.buckets);

    if (event.latency.count > 0) {
      minMs = latencyCount == 0
          ? event.latency.minMs
          : (event.latency.minMs < minMs ? event.latency.minMs : minMs);
      maxMs = event.latency.maxMs > maxMs ? event.latency.maxMs : maxMs;
      sumMs += event.latency.sumMs;
      latencyCount += event.latency.count;
    }
  }

  NodeMetricsSnapshot toSnapshot() {
    return NodeMetricsSnapshot(
      nodeId: nodeId,
      requestCount: requestCount,
      errorCount: errorCount,
      statusCounts: Map.unmodifiable(statusCounts),
      errorTypeCounts: Map.unmodifiable(errorTypeCounts),
      latency: LatencyHistogram(
        buckets: Map.unmodifiable(buckets),
        minMs: minMs,
        maxMs: maxMs,
        sumMs: sumMs,
        count: latencyCount,
      ),
    );
  }

  void _mergeStringCounts(Map<String, int> target, Map<String, int> source) {
    for (final entry in source.entries) {
      target[entry.key] = (target[entry.key] ?? 0) + entry.value;
    }
  }

  void _mergeIntCounts(Map<int, int> target, Map<int, int> source) {
    for (final entry in source.entries) {
      target[entry.key] = (target[entry.key] ?? 0) + entry.value;
    }
  }
}
