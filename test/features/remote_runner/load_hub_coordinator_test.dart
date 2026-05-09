import 'package:apilens/features/remote_runner/application/load_hub_coordinator.dart';
import 'package:apilens/features/remote_runner/data/agent_client.dart';
import 'package:apilens/features/remote_runner/domain/models/load_profile.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_agent.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_run.dart';
import 'package:apilens/features/remote_runner/domain/models/run_shard.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow_edge.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadHubCoordinator', () {
    test('dispatches shards and completes run with fake agent client',
        () async {
      final client = FakeAgentClient();
      final coordinator = LoadHubCoordinator(
        agentClient: client,
        now: () => DateTime.utc(2026, 5, 9, 12),
      );
      addTearDown(client.close);
      addTearDown(coordinator.dispose);

      final state = await coordinator.startRun(
        draft: _draft(),
        agents: [_agent('agent-1')],
      );

      expect(state.status, RemoteRunStatus.completed);
      expect(state.shardsById.values.single.status, RunShardStatus.completed);
      expect(state.metrics, hasLength(1));
    });

    test('cancels non-terminal shards', () async {
      final client = FakeAgentClient(autoComplete: false);
      final coordinator = LoadHubCoordinator(
        agentClient: client,
        now: () => DateTime.utc(2026, 5, 9, 12),
      );
      addTearDown(client.close);
      addTearDown(coordinator.dispose);

      await coordinator.startRun(
        draft: _draft(),
        agents: [_agent('agent-1')],
      );
      await coordinator.cancelRun('run-1');
      await Future<void>.delayed(Duration.zero);

      final state = coordinator.getRun('run-1');
      expect(state?.status, RemoteRunStatus.cancelled);
      expect(state?.shardsById.values.single.status, RunShardStatus.cancelled);
    });

    test('marks active shard lost when agent disconnects', () async {
      final client = FakeAgentClient(autoComplete: false);
      final coordinator = LoadHubCoordinator(
        agentClient: client,
        now: () => DateTime.utc(2026, 5, 9, 12),
      );
      addTearDown(client.close);
      addTearDown(coordinator.dispose);

      await coordinator.startRun(
        draft: _draft(),
        agents: [_agent('agent-1')],
      );
      client.disconnect('agent-1');
      await Future<void>.delayed(Duration.zero);

      final state = coordinator.getRun('run-1');
      expect(state?.status, RemoteRunStatus.failed);
      expect(state?.shardsById.values.single.status, RunShardStatus.lost);
    });
  });
}

RemoteRunDraft _draft() {
  return RemoteRunDraft(
    id: 'run-1',
    workflowSnapshot: Workflow(
      id: 'wf-1',
      name: 'Workflow',
      nodes: [
        WorkflowNode(id: 'start', type: 'start', x: 0, y: 0),
        WorkflowNode(id: 'api1', type: 'api', x: 100, y: 0, data: {
          'type': 'http',
          'url': 'https://example.test',
          'method': 'GET',
        }),
        WorkflowNode(id: 'end', type: 'end', x: 200, y: 0),
      ],
      edges: [
        WorkflowEdge(sourceNodeId: 'start', targetNodeId: 'api1'),
      ],
    ),
    loadProfile: const LoadProfile(
      virtualUsers: 10,
      durationSeconds: 10,
    ),
    createdAt: DateTime.utc(2026, 5, 9),
  );
}

RemoteAgent _agent(String id) {
  return RemoteAgent(
    id: id,
    machineId: '$id-machine',
    endpoint: 'ws://$id',
    version: '1.0.0',
    protocolVersion: '1',
    capacity: const RemoteAgentCapacity(
      maxVirtualUsers: 100,
      maxConcurrency: 25,
    ),
    status: RemoteAgentStatus.online,
  );
}
