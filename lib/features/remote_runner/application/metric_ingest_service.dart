import 'backpressure_controller.dart';
import 'metrics_aggregator.dart';
import '../domain/models/metric_window_event.dart';
import '../domain/models/metrics_models.dart';

enum MetricIngestStatus {
  accepted,
  duplicate,
  gapDetected,
  dropped,
}

class MetricIngestResult {
  final MetricIngestStatus status;
  final String? message;
  final BackpressureCommand? backpressureCommand;

  const MetricIngestResult({
    required this.status,
    this.message,
    this.backpressureCommand,
  });
}

class MetricIngestService {
  final MetricsAggregator aggregator;
  final BackpressureController backpressureController;
  final int maxQueueDepth;
  final Set<String> _seenEventIds = {};
  final Map<String, int> _lastSequenceByStream = {};
  var _queueDepth = 0;
  var _droppedEventCount = 0;

  MetricIngestService({
    MetricsAggregator? aggregator,
    BackpressureController? backpressureController,
    this.maxQueueDepth = 1000,
  })  : aggregator = aggregator ?? MetricsAggregator(),
        backpressureController =
            backpressureController ?? const BackpressureController();

  IngestQueueState get queueState => IngestQueueState(
        queueDepth: _queueDepth,
        droppedEventCount: _droppedEventCount,
      );

  MetricIngestResult ingest(MetricWindowEvent event) {
    if (_seenEventIds.contains(event.id)) {
      return const MetricIngestResult(status: MetricIngestStatus.duplicate);
    }
    if (_queueDepth >= maxQueueDepth) {
      _droppedEventCount++;
      final command = backpressureController.evaluate(
        agentId: event.agentId,
        queue: queueState,
      );
      return MetricIngestResult(
        status: MetricIngestStatus.dropped,
        message: 'ingest queue is full',
        backpressureCommand: command,
      );
    }

    _queueDepth++;
    try {
      _seenEventIds.add(event.id);
      final streamKey = _streamKey(event);
      final lastSequence = _lastSequenceByStream[streamKey];
      final gapDetected =
          lastSequence != null && event.sequence > lastSequence + 1;
      _lastSequenceByStream[streamKey] = event.sequence;
      aggregator.add(event);

      final command = backpressureController.evaluate(
        agentId: event.agentId,
        queue: queueState,
      );
      if (gapDetected) {
        return MetricIngestResult(
          status: MetricIngestStatus.gapDetected,
          message: 'metric sequence gap detected',
          backpressureCommand: command.isNoop ? null : command,
        );
      }
      return MetricIngestResult(
        status: MetricIngestStatus.accepted,
        backpressureCommand: command.isNoop ? null : command,
      );
    } finally {
      _queueDepth--;
    }
  }

  RunMetricsSnapshot snapshot(String runId) {
    return aggregator.snapshot(runId);
  }

  String _streamKey(MetricWindowEvent event) {
    return '${event.runId}/${event.shardId}/${event.agentId}/${event.nodeId}';
  }
}
