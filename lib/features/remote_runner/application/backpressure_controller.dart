import '../domain/models/metrics_models.dart';

class BackpressurePolicy {
  final int maxQueueDepth;
  final Duration maxIngestLag;
  final int increasedMetricWindowMs;
  final double reducedSamplingRate;

  const BackpressurePolicy({
    this.maxQueueDepth = 1000,
    this.maxIngestLag = const Duration(seconds: 2),
    this.increasedMetricWindowMs = 5000,
    this.reducedSamplingRate = 0.1,
  });
}

class BackpressureController {
  final BackpressurePolicy policy;

  const BackpressureController({
    this.policy = const BackpressurePolicy(),
  });

  BackpressureCommand evaluate({
    required String agentId,
    required IngestQueueState queue,
  }) {
    if (queue.queueDepth >= policy.maxQueueDepth * 2) {
      return BackpressureCommand(
        agentId: agentId,
        action: BackpressureAction.pauseRawEvents,
        reason: 'ingest queue depth is critically high',
      );
    }
    if (queue.queueDepth >= policy.maxQueueDepth) {
      return BackpressureCommand(
        agentId: agentId,
        action: BackpressureAction.increaseMetricWindow,
        metricWindowMs: policy.increasedMetricWindowMs,
        reason: 'ingest queue depth exceeded',
      );
    }
    if (queue.ingestLag > policy.maxIngestLag) {
      return BackpressureCommand(
        agentId: agentId,
        action: BackpressureAction.reduceSampling,
        samplingRate: policy.reducedSamplingRate,
        reason: 'ingest lag exceeded',
      );
    }
    return BackpressureCommand(
      agentId: agentId,
      action: BackpressureAction.none,
    );
  }
}
