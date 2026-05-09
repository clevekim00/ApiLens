import 'package:apilens/features/remote_runner/application/remote_run_planner.dart';
import 'package:apilens/features/remote_runner/domain/models/load_profile.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_agent.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_run.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow_edge.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteRunPlanner', () {
    const planner = RemoteRunPlanner();
    final plannedAt = DateTime.utc(2026, 5, 9, 12);

    test('creates deterministic equal-split shards', () {
      final draft = _draft(
        loadProfile: const LoadProfile(
          virtualUsers: 10,
          durationSeconds: 60,
          rampUpSeconds: 10,
          distributionPolicy: LoadDistributionPolicy.equalSplit,
        ),
      );

      final first = planner.plan(
        draft: draft,
        agents: [
          _agent('agent-b', maxVirtualUsers: 100),
          _agent('agent-a', maxVirtualUsers: 100),
        ],
        plannedAt: plannedAt,
      );
      final second = planner.plan(
        draft: draft,
        agents: [
          _agent('agent-b', maxVirtualUsers: 100),
          _agent('agent-a', maxVirtualUsers: 100),
        ],
        plannedAt: plannedAt,
      );

      expect(first.toJson(), second.toJson());
      expect(first.shards.map((shard) => shard.id), [
        'run-1-shard-001',
        'run-1-shard-002',
      ]);
      expect(first.shards.map((shard) => shard.agentId), [
        'agent-a',
        'agent-b',
      ]);
      expect(first.shards[0].virtualUserRange.count, 5);
      expect(first.shards[1].virtualUserRange.count, 5);
      expect(first.shards[1].rampUpOffsetMs, 5000);
    });

    test('uses capacity-weighted split', () {
      final plan = planner.plan(
        draft: _draft(
          loadProfile: const LoadProfile(
            virtualUsers: 100,
            durationSeconds: 60,
            distributionPolicy: LoadDistributionPolicy.capacityWeighted,
          ),
        ),
        agents: [
          _agent('agent-small', maxVirtualUsers: 100),
          _agent('agent-large', maxVirtualUsers: 300),
        ],
        plannedAt: plannedAt,
      );

      final allocationByAgent = {
        for (final shard in plan.shards)
          shard.agentId: shard.virtualUserRange.count,
      };

      expect(allocationByAgent['agent-large'], 75);
      expect(allocationByAgent['agent-small'], 25);
    });

    test('excludes non-schedulable agents', () {
      final plan = planner.plan(
        draft: _draft(
          loadProfile: const LoadProfile(
            virtualUsers: 10,
            durationSeconds: 60,
          ),
        ),
        agents: [
          _agent('agent-offline',
              maxVirtualUsers: 100, status: RemoteAgentStatus.offline),
          _agent('agent-online', maxVirtualUsers: 100),
        ],
        plannedAt: plannedAt,
      );

      expect(plan.shards, hasLength(1));
      expect(plan.shards.single.agentId, 'agent-online');
      expect(plan.shards.single.virtualUserRange.count, 10);
    });

    test('throws planning failure when capacity is insufficient', () {
      expect(
        () => planner.plan(
          draft: _draft(
            loadProfile: const LoadProfile(
              virtualUsers: 200,
              durationSeconds: 60,
            ),
          ),
          agents: [_agent('agent-1', maxVirtualUsers: 50)],
          plannedAt: plannedAt,
        ),
        throwsA(isA<RemoteRunPlanningFailure>().having(
          (failure) => failure.code,
          'code',
          'agents.capacity_insufficient',
        )),
      );
    });
  });
}

RemoteRunDraft _draft({required LoadProfile loadProfile}) {
  return RemoteRunDraft(
    id: 'run-1',
    workflowSnapshot: Workflow(
      id: 'wf-1',
      name: 'API workflow',
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
        WorkflowEdge(
          sourceNodeId: 'api1',
          sourcePort: 'success',
          targetNodeId: 'end',
        ),
      ],
    ),
    loadProfile: loadProfile,
    createdAt: DateTime.utc(2026, 5, 9),
  );
}

RemoteAgent _agent(
  String id, {
  required int maxVirtualUsers,
  RemoteAgentStatus status = RemoteAgentStatus.online,
}) {
  return RemoteAgent(
    id: id,
    machineId: '$id-machine',
    endpoint: 'ws://$id',
    version: '1.0.0',
    protocolVersion: '1',
    capacity: RemoteAgentCapacity(
      maxVirtualUsers: maxVirtualUsers,
      maxConcurrency: maxVirtualUsers,
    ),
    status: status,
  );
}
