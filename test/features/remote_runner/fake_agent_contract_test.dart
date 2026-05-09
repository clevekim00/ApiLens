import 'package:apilens/features/remote_runner/data/agent_client.dart';
import 'package:apilens/features/remote_runner/domain/models/load_profile.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_run.dart';
import 'package:apilens/features/remote_runner/domain/models/run_shard.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FakeAgentClient emits running, metric, and completed events', () async {
    final client = FakeAgentClient();
    final events = <AgentClientEvent>[];
    final subscription = client.events.listen(events.add);
    addTearDown(subscription.cancel);
    addTearDown(client.close);

    await client.dispatchShard(
      draft: RemoteRunDraft(
        id: 'run-1',
        workflowSnapshot: Workflow(
          id: 'wf-1',
          name: 'Workflow',
          nodes: const [],
          edges: const [],
        ),
        loadProfile: const LoadProfile(
          virtualUsers: 10,
          durationSeconds: 10,
        ),
        createdAt: DateTime.utc(2026, 5, 9),
      ),
      shard: const RunShard(
        id: 'run-1-shard-001',
        runId: 'run-1',
        agentId: 'agent-1',
        virtualUserRange: VirtualUserRange(
          startInclusive: 1,
          endInclusive: 10,
        ),
        rampUpOffsetMs: 0,
        durationSeconds: 10,
        concurrencyLimit: 10,
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(
        events.whereType<AgentShardStatusEvent>().map((event) {
          return event.status;
        }),
        containsAll([
          RunShardStatus.running,
          RunShardStatus.completed,
        ]));
    expect(events.whereType<AgentMetricWindowEvent>(), hasLength(1));
  });
}
