import 'dart:async';

import '../domain/models/metric_window_event.dart';
import '../domain/models/remote_run.dart';
import '../domain/models/run_shard.dart';

abstract class AgentClientEvent {
  final String agentId;

  const AgentClientEvent(this.agentId);
}

class AgentShardStatusEvent extends AgentClientEvent {
  final String shardId;
  final RunShardStatus status;
  final String? message;

  const AgentShardStatusEvent({
    required String agentId,
    required this.shardId,
    required this.status,
    this.message,
  }) : super(agentId);
}

class AgentMetricWindowEvent extends AgentClientEvent {
  final MetricWindowEvent metric;

  const AgentMetricWindowEvent({
    required String agentId,
    required this.metric,
  }) : super(agentId);
}

class AgentDisconnectedEvent extends AgentClientEvent {
  final String reason;

  const AgentDisconnectedEvent({
    required String agentId,
    required this.reason,
  }) : super(agentId);
}

abstract class AgentClient {
  Stream<AgentClientEvent> get events;

  Future<void> dispatchShard({
    required RemoteRunDraft draft,
    required RunShard shard,
  });

  Future<void> cancelShard({
    required String agentId,
    required String shardId,
  });

  Future<void> drainAgent(String agentId);
}

class FakeAgentClient implements AgentClient {
  final StreamController<AgentClientEvent> _events =
      StreamController<AgentClientEvent>.broadcast(sync: true);
  final Duration eventDelay;
  final bool autoComplete;

  FakeAgentClient({
    this.eventDelay = Duration.zero,
    this.autoComplete = true,
  });

  @override
  Stream<AgentClientEvent> get events => _events.stream;

  @override
  Future<void> dispatchShard({
    required RemoteRunDraft draft,
    required RunShard shard,
  }) async {
    _emit(AgentShardStatusEvent(
      agentId: shard.agentId,
      shardId: shard.id,
      status: RunShardStatus.running,
    ));

    if (!autoComplete) return;

    await Future<void>.delayed(eventDelay);
    _emit(AgentMetricWindowEvent(
      agentId: shard.agentId,
      metric: MetricWindowEvent(
        id: '${shard.id}-metric-001',
        runId: shard.runId,
        shardId: shard.id,
        agentId: shard.agentId,
        nodeId: 'workflow',
        windowStartedAt: DateTime.now(),
        windowMs: 1000,
        sequence: 1,
        requestCount: shard.virtualUserRange.count,
        errorCount: 0,
        statusCounts: const {'success': 1},
        latency: LatencyHistogram(
          buckets: {100: shard.virtualUserRange.count},
          minMs: 1,
          maxMs: 100,
          sumMs: shard.virtualUserRange.count * 50,
          count: shard.virtualUserRange.count,
        ),
      ),
    ));
    _emit(AgentShardStatusEvent(
      agentId: shard.agentId,
      shardId: shard.id,
      status: RunShardStatus.completed,
    ));
  }

  @override
  Future<void> cancelShard({
    required String agentId,
    required String shardId,
  }) async {
    _emit(AgentShardStatusEvent(
      agentId: agentId,
      shardId: shardId,
      status: RunShardStatus.cancelled,
    ));
  }

  @override
  Future<void> drainAgent(String agentId) async {}

  void disconnect(String agentId, {String reason = 'simulated disconnect'}) {
    _emit(AgentDisconnectedEvent(agentId: agentId, reason: reason));
  }

  Future<void> close() async {
    await _events.close();
  }

  void _emit(AgentClientEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }
}
