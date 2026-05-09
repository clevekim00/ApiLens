import 'package:apilens/features/remote_runner/application/metric_ingest_service.dart';
import 'package:apilens/features/remote_runner/application/metrics_aggregator.dart';
import 'package:apilens/features/remote_runner/domain/models/metric_window_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetricsAggregator', () {
    test('merges counts and estimates percentiles from histogram buckets', () {
      final aggregator = MetricsAggregator(
        now: () => DateTime.utc(2026, 5, 9, 12),
      );

      aggregator.add(_event(
        id: 'event-1',
        sequence: 1,
        requestCount: 10,
        errorCount: 1,
        buckets: const {100: 7, 250: 3},
      ));
      aggregator.add(_event(
        id: 'event-2',
        sequence: 2,
        requestCount: 10,
        errorCount: 2,
        buckets: const {100: 3, 500: 7},
      ));

      final snapshot = aggregator.snapshot('run-1');

      expect(snapshot.requestCount, 20);
      expect(snapshot.errorCount, 3);
      expect(snapshot.node('api1')?.statusCounts['200'], 17);
      expect(snapshot.node('api1')?.statusCounts['500'], 3);
      expect(aggregator.percentileMs('run-1', 'api1', 0.5), 100);
      expect(aggregator.percentileMs('run-1', 'api1', 0.95), 500);
    });
  });

  group('MetricIngestService', () {
    test('dedupes event ids and detects sequence gaps', () {
      final service = MetricIngestService();

      expect(service.ingest(_event(id: 'event-1', sequence: 1)).status,
          MetricIngestStatus.accepted);
      expect(service.ingest(_event(id: 'event-1', sequence: 1)).status,
          MetricIngestStatus.duplicate);
      expect(service.ingest(_event(id: 'event-3', sequence: 3)).status,
          MetricIngestStatus.gapDetected);

      final snapshot = service.snapshot('run-1');
      expect(snapshot.requestCount, 2);
    });
  });
}

MetricWindowEvent _event({
  required String id,
  required int sequence,
  int requestCount = 1,
  int errorCount = 0,
  Map<int, int> buckets = const {100: 1},
}) {
  return MetricWindowEvent(
    id: id,
    runId: 'run-1',
    shardId: 'shard-1',
    agentId: 'agent-1',
    nodeId: 'api1',
    windowStartedAt: DateTime.utc(2026, 5, 9, 12),
    windowMs: 1000,
    sequence: sequence,
    requestCount: requestCount,
    errorCount: errorCount,
    statusCounts: {
      '200': requestCount - errorCount,
      if (errorCount > 0) '500': errorCount,
    },
    errorTypeCounts: {
      if (errorCount > 0) 'http_500': errorCount,
    },
    latency: LatencyHistogram(
      buckets: buckets,
      minMs: buckets.keys.reduce((a, b) => a < b ? a : b),
      maxMs: buckets.keys.reduce((a, b) => a > b ? a : b),
      sumMs: buckets.entries.fold<int>(
        0,
        (sum, entry) => sum + entry.key * entry.value,
      ),
      count: buckets.values.fold<int>(0, (sum, value) => sum + value),
    ),
  );
}
