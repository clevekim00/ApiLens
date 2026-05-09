import 'dart:io';

import 'package:apilens/features/remote_runner/application/load_hub_coordinator.dart';
import 'package:apilens/features/remote_runner/data/agent_client.dart';
import 'package:apilens/features/remote_runner/domain/models/load_profile.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_agent.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_run.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow_edge.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow_node.dart';

Future<void> main() async {
  final client = FakeAgentClient();
  final coordinator = LoadHubCoordinator(agentClient: client);

  final state = await coordinator.startRun(
    draft: _draft(),
    agents: const [
      RemoteAgent(
        id: 'agent-1',
        machineId: 'machine-1',
        endpoint: 'memory://agent-1',
        version: '1.0.0',
        protocolVersion: '1',
        capacity: RemoteAgentCapacity(maxVirtualUsers: 50, maxConcurrency: 10),
        status: RemoteAgentStatus.online,
      ),
      RemoteAgent(
        id: 'agent-2',
        machineId: 'machine-2',
        endpoint: 'memory://agent-2',
        version: '1.0.0',
        protocolVersion: '1',
        capacity: RemoteAgentCapacity(maxVirtualUsers: 50, maxConcurrency: 10),
        status: RemoteAgentStatus.online,
      ),
    ],
  );

  stdout.writeln('run=${state.plan.id} status=${state.status.name}');
  stdout.writeln(
      'shards=${state.shardsById.length} metrics=${state.metrics.length}');
  await coordinator.dispose();
  await client.close();
}

RemoteRunDraft _draft() {
  return RemoteRunDraft(
    id: 'run-script',
    workflowSnapshot: Workflow(
      id: 'wf-script',
      name: 'Script workflow',
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
      virtualUsers: 100,
      durationSeconds: 30,
      distributionPolicy: LoadDistributionPolicy.equalSplit,
    ),
    createdAt: DateTime.now(),
  );
}
