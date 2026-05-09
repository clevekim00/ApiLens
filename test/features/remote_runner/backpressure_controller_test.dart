import 'package:apilens/features/remote_runner/application/backpressure_controller.dart';
import 'package:apilens/features/remote_runner/application/metric_ingest_service.dart';
import 'package:apilens/features/remote_runner/domain/models/metric_window_event.dart';
import 'package:apilens/features/remote_runner/domain/models/metrics_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackpressureController', () {
    test('returns noop when queue is healthy', () {
      const controller = BackpressureController();

      final command = controller.evaluate(
        agentId: 'agent-1',
        queue: const IngestQueueState(queueDepth: 1),
      );

      expect(command.action, BackpressureAction.none);
    });

    test('increases metric window when queue depth is high', () {
      const controller = BackpressureController(
        policy: BackpressurePolicy(maxQueueDepth: 10),
      );

      final command = controller.evaluate(
        agentId: 'agent-1',
        queue: const IngestQueueState(queueDepth: 10),
      );

      expect(command.action, BackpressureAction.increaseMetricWindow);
      expect(command.metricWindowMs, 5000);
    });

    test('pauses raw events when queue depth is critical', () {
      const controller = BackpressureController(
        policy: BackpressurePolicy(maxQueueDepth: 10),
      );

      final command = controller.evaluate(
        agentId: 'agent-1',
        queue: const IngestQueueState(queueDepth: 20),
      );

      expect(command.action, BackpressureAction.pauseRawEvents);
    });

    test('metric ingest returns backpressure command near queue limit', () {
      final service = MetricIngestService(
        maxQueueDepth: 2,
        backpressureController: const BackpressureController(
          policy: BackpressurePolicy(maxQueueDepth: 1),
        ),
      );

      final result = service.ingest(MetricWindowEvent(
        id: 'event-1',
        runId: 'run-1',
        shardId: 'shard-1',
        agentId: 'agent-1',
        nodeId: 'api1',
        windowStartedAt: DateTime.utc(2026, 5, 9),
        windowMs: 1000,
        sequence: 1,
        requestCount: 1,
        errorCount: 0,
      ));

      expect(result.status, MetricIngestStatus.accepted);
      expect(result.backpressureCommand?.action,
          BackpressureAction.increaseMetricWindow);
    });
  });
}
