import 'dart:async';

import '../data/agent_client.dart';
import '../domain/models/metric_window_event.dart';
import '../domain/models/remote_agent.dart';
import '../domain/models/remote_run.dart';
import '../domain/models/run_shard.dart';
import 'remote_run_planner.dart';

class LoadHubRunState {
  final RemoteRunPlan plan;
  final Map<String, RunShard> shardsById;
  final List<MetricWindowEvent> metrics;

  const LoadHubRunState({
    required this.plan,
    required this.shardsById,
    this.metrics = const [],
  });

  RemoteRunStatus get status => plan.status;

  bool get isTerminal {
    return status == RemoteRunStatus.completed ||
        status == RemoteRunStatus.failed ||
        status == RemoteRunStatus.cancelled;
  }

  LoadHubRunState copyWith({
    RemoteRunPlan? plan,
    Map<String, RunShard>? shardsById,
    List<MetricWindowEvent>? metrics,
  }) {
    return LoadHubRunState(
      plan: plan ?? this.plan,
      shardsById: shardsById ?? this.shardsById,
      metrics: metrics ?? this.metrics,
    );
  }
}

class LoadHubCoordinator {
  final AgentClient _agentClient;
  final RemoteRunPlanner _planner;
  final DateTime Function() _now;
  final Map<String, LoadHubRunState> _runs = {};
  late final StreamSubscription<AgentClientEvent> _eventSubscription;

  LoadHubCoordinator({
    required AgentClient agentClient,
    RemoteRunPlanner planner = const RemoteRunPlanner(),
    DateTime Function()? now,
  })  : _agentClient = agentClient,
        _planner = planner,
        _now = now ?? DateTime.now {
    _eventSubscription = _agentClient.events.listen(_handleAgentEvent);
  }

  List<LoadHubRunState> get runs {
    return _runs.values.toList()
      ..sort((a, b) => a.plan.id.compareTo(b.plan.id));
  }

  LoadHubRunState? getRun(String runId) => _runs[runId];

  Future<LoadHubRunState> startRun({
    required RemoteRunDraft draft,
    required List<RemoteAgent> agents,
  }) async {
    final plan = _planner.plan(
      draft: draft,
      agents: agents,
      plannedAt: _now(),
    );
    final runningPlan = plan.copyWith(status: RemoteRunStatus.running);
    final shardsById = {
      for (final shard in runningPlan.shards)
        shard.id: shard.copyWith(status: RunShardStatus.dispatching),
    };
    final state = LoadHubRunState(
      plan: runningPlan,
      shardsById: shardsById,
    );
    _runs[draft.id] = state;

    for (final shard in shardsById.values) {
      await _agentClient.dispatchShard(
        draft: draft,
        shard: shard,
      );
    }

    return _runs[draft.id] ?? state;
  }

  Future<void> cancelRun(String runId) async {
    final state = _runs[runId];
    if (state == null || state.isTerminal) return;

    for (final shard in state.shardsById.values) {
      if (shard.status == RunShardStatus.completed ||
          shard.status == RunShardStatus.failed ||
          shard.status == RunShardStatus.cancelled) {
        continue;
      }
      await _agentClient.cancelShard(
        agentId: shard.agentId,
        shardId: shard.id,
      );
    }
    final latest = _runs[runId] ?? state;
    _replaceRunState(
      runId,
      latest.copyWith(
        plan: latest.plan.copyWith(status: RemoteRunStatus.cancelled),
      ),
    );
  }

  Future<void> dispose() async {
    await _eventSubscription.cancel();
  }

  void _handleAgentEvent(AgentClientEvent event) {
    if (event is AgentShardStatusEvent) {
      _handleShardStatus(event);
    } else if (event is AgentMetricWindowEvent) {
      _handleMetric(event.metric);
    } else if (event is AgentDisconnectedEvent) {
      _handleDisconnect(event);
    }
  }

  void _handleShardStatus(AgentShardStatusEvent event) {
    final runId = _runIdForShard(event.shardId);
    final state = _runs[runId];
    if (state == null) return;
    final shard = state.shardsById[event.shardId];
    if (shard == null) return;

    final updatedShards = Map<String, RunShard>.from(state.shardsById);
    updatedShards[event.shardId] = shard.copyWith(status: event.status);
    final updatedState = state.copyWith(shardsById: updatedShards);
    _replaceRunState(runId, _withDerivedRunStatus(updatedState));
  }

  void _handleMetric(MetricWindowEvent metric) {
    final state = _runs[metric.runId];
    if (state == null) return;
    _replaceRunState(
        metric.runId,
        state.copyWith(
          metrics: [...state.metrics, metric],
        ));
  }

  void _handleDisconnect(AgentDisconnectedEvent event) {
    for (final state in _runs.values.toList()) {
      if (state.isTerminal) continue;
      var changed = false;
      final updatedShards = Map<String, RunShard>.from(state.shardsById);
      for (final entry in state.shardsById.entries) {
        final shard = entry.value;
        if (shard.agentId != event.agentId) continue;
        if (shard.status == RunShardStatus.completed ||
            shard.status == RunShardStatus.failed ||
            shard.status == RunShardStatus.cancelled) {
          continue;
        }
        updatedShards[entry.key] = shard.copyWith(status: RunShardStatus.lost);
        changed = true;
      }
      if (changed) {
        _replaceRunState(
          state.plan.draft.id,
          state.copyWith(shardsById: updatedShards).copyWith(
                plan: state.plan.copyWith(status: RemoteRunStatus.failed),
              ),
        );
      }
    }
  }

  LoadHubRunState _withDerivedRunStatus(LoadHubRunState state) {
    final statuses = state.shardsById.values.map((shard) => shard.status);
    if (statuses.any((status) =>
        status == RunShardStatus.failed || status == RunShardStatus.lost)) {
      return state.copyWith(
        plan: state.plan.copyWith(status: RemoteRunStatus.failed),
      );
    }
    if (statuses.isNotEmpty &&
        statuses.every((status) => status == RunShardStatus.completed)) {
      return state.copyWith(
        plan: state.plan.copyWith(status: RemoteRunStatus.completed),
      );
    }
    if (statuses.every((status) => status == RunShardStatus.cancelled)) {
      return state.copyWith(
        plan: state.plan.copyWith(status: RemoteRunStatus.cancelled),
      );
    }
    return state.copyWith(
      plan: state.plan.copyWith(status: RemoteRunStatus.running),
    );
  }

  String _runIdForShard(String shardId) {
    final markerIndex = shardId.lastIndexOf('-shard-');
    if (markerIndex == -1) return shardId;
    return shardId.substring(0, markerIndex);
  }

  void _replaceRunState(String runId, LoadHubRunState state) {
    _runs[runId] = state;
  }
}
