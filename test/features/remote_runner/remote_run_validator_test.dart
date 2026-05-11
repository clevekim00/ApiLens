import 'package:apilens/features/remote_runner/application/remote_run_validator.dart';
import 'package:apilens/features/remote_runner/domain/models/agent_upgrade.dart';
import 'package:apilens/features/remote_runner/domain/models/load_profile.dart';
import 'package:apilens/features/remote_runner/domain/models/machine_resource_snapshot.dart';
import 'package:apilens/features/remote_runner/domain/models/metric_window_event.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_agent.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_machine.dart';
import 'package:apilens/features/remote_runner/domain/models/run_shard.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow_edge.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Load Hub remote runner models', () {
    test('round-trips machine and agent JSON', () {
      final now = DateTime.utc(2026, 5, 9, 12);
      final machine = RemoteMachine(
        id: 'machine-1',
        name: 'Seoul generator',
        host: '10.0.0.10',
        platform: 'linux-x64',
        labels: const ['kr', 'staging'],
        credentialRef: 'cred-1',
        agentInstallPath: '/opt/apilens-agent',
        adminState: RemoteMachineAdminState.draining,
        lastSeenAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final agent = RemoteAgent(
        id: 'agent-1',
        machineId: machine.id,
        endpoint: 'ws://10.0.0.10:8787',
        version: '1.2.3',
        protocolVersion: '1',
        tags: const ['kr'],
        supportedNodeTypes: const ['api', 'gql_request'],
        capacity: const RemoteAgentCapacity(
          maxVirtualUsers: 500,
          maxConcurrency: 100,
          weight: 2,
        ),
        status: RemoteAgentStatus.online,
        lastHeartbeatAt: now,
        resourceSnapshot: MachineResourceSnapshot(
          cpuUsagePercent: 64.5,
          memoryUsagePercent: 70.2,
          memoryUsedBytes: 6 * 1024 * 1024 * 1024,
          memoryTotalBytes: 8 * 1024 * 1024 * 1024,
          diskReadBytesPerSecond: 12 * 1024 * 1024,
          diskWriteBytesPerSecond: 4 * 1024 * 1024,
          networkRxBytesPerSecond: 2 * 1024 * 1024,
          networkTxBytesPerSecond: 8 * 1024 * 1024,
          loadAverage1m: 1.7,
          capturedAt: now,
        ),
      );

      final decodedMachine = RemoteMachine.fromJson(machine.toJson());
      final decodedAgent = RemoteAgent.fromJson(agent.toJson());

      expect(decodedMachine.adminState, RemoteMachineAdminState.draining);
      expect(decodedMachine.labels, ['kr', 'staging']);
      expect(decodedAgent.status, RemoteAgentStatus.online);
      expect(decodedAgent.capacity.maxVirtualUsers, 500);
      expect(decodedAgent.resourceSnapshot?.cpuUsagePercent, 64.5);
      expect(decodedAgent.resourceSnapshot?.isUnderPressure, isFalse);
      expect(decodedAgent.supportsNodeType('api'), isTrue);
      expect(decodedAgent.supportsNodeType('ws_connect'), isFalse);
    });

    test('round-trips metric window and upgrade plan JSON', () {
      final window = MetricWindowEvent(
        id: 'event-1',
        runId: 'run-1',
        shardId: 'shard-1',
        agentId: 'agent-1',
        nodeId: 'api1',
        windowStartedAt: DateTime.utc(2026, 5, 9, 12),
        windowMs: 1000,
        sequence: 7,
        requestCount: 120,
        errorCount: 3,
        statusCounts: const {'200': 117, '500': 3},
        errorTypeCounts: const {'http_500': 3},
        latency: const LatencyHistogram(
          buckets: {100: 80, 250: 37, 500: 3},
          minMs: 12,
          maxMs: 430,
          sumMs: 14800,
          count: 120,
        ),
      );
      const plan = AgentUpgradePlan(
        id: 'upgrade-1',
        machineIds: ['machine-1', 'machine-2'],
        targetVersion: AgentVersionManifest(
          version: '2.0.0',
          protocolVersion: '1',
          packageUrl: 'https://example.test/agent.tar.gz',
          checksum: 'sha256:abc',
          rollbackPackageUrl: 'https://example.test/agent-rollback.tar.gz',
        ),
        batchSize: 2,
        drainTimeoutSeconds: 60,
      );

      final decodedWindow = MetricWindowEvent.fromJson(window.toJson());
      final decodedPlan = AgentUpgradePlan.fromJson(plan.toJson());

      expect(decodedWindow.statusCounts['200'], 117);
      expect(decodedWindow.latency.buckets[250], 37);
      expect(decodedPlan.targetVersion.version, '2.0.0');
      expect(decodedPlan.machineIds, ['machine-1', 'machine-2']);
      expect(decodedPlan.batchSize, 2);
    });

    test('round-trips run shard JSON', () {
      const shard = RunShard(
        id: 'shard-1',
        runId: 'run-1',
        agentId: 'agent-1',
        virtualUserRange: VirtualUserRange(
          startInclusive: 1,
          endInclusive: 100,
        ),
        rampUpOffsetMs: 500,
        durationSeconds: 60,
        concurrencyLimit: 25,
      );

      final decoded = RunShard.fromJson(shard.toJson());

      expect(decoded.virtualUserRange.count, 100);
      expect(decoded.status, RunShardStatus.queued);
      expect(decoded.concurrencyLimit, 25);
    });
  });

  group('RemoteRunValidator', () {
    const validator = RemoteRunValidator();

    test('accepts valid workflow, load profile, and schedulable agent', () {
      final result = validator.validate(
        workflow: _workflow(),
        loadProfile: const LoadProfile(
          virtualUsers: 10,
          durationSeconds: 30,
        ),
        agents: const [
          RemoteAgent(
            id: 'agent-1',
            machineId: 'machine-1',
            endpoint: 'ws://agent-1',
            version: '1.0.0',
            protocolVersion: '1',
            supportedNodeTypes: ['api'],
            capacity: RemoteAgentCapacity(
              maxVirtualUsers: 100,
              maxConcurrency: 20,
            ),
            status: RemoteAgentStatus.online,
          ),
        ],
      );

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('returns error when no agent is schedulable', () {
      final result = validator.validate(
        workflow: _workflow(),
        loadProfile: const LoadProfile(
          virtualUsers: 10,
          durationSeconds: 30,
        ),
        agents: const [],
      );

      expect(result.isValid, isFalse);
      expect(
          result.errors.map((issue) => issue.code),
          contains(
            'agents.none_schedulable',
          ));
    });

    test('returns error when agent capacity is lower than requested VUs', () {
      final result = validator.validate(
        workflow: _workflow(),
        loadProfile: const LoadProfile(
          virtualUsers: 200,
          durationSeconds: 30,
        ),
        agents: const [
          RemoteAgent(
            id: 'agent-1',
            machineId: 'machine-1',
            endpoint: 'ws://agent-1',
            version: '1.0.0',
            protocolVersion: '1',
            supportedNodeTypes: ['api'],
            capacity: RemoteAgentCapacity(
              maxVirtualUsers: 50,
              maxConcurrency: 20,
            ),
            status: RemoteAgentStatus.online,
          ),
        ],
      );

      expect(result.isValid, isFalse);
      expect(
          result.errors.map((issue) => issue.code),
          contains(
            'agents.capacity_insufficient',
          ));
    });

    test('returns error for invalid workflow graph', () {
      final result = validator.validate(
        workflow: Workflow(
          id: 'wf-bad',
          name: 'Bad workflow',
          nodes: [
            WorkflowNode(id: 'api1', type: 'api', x: 0, y: 0, data: {
              'type': 'http',
              'url': 'https://example.test',
              'method': 'GET',
            }),
          ],
          edges: const [],
        ),
        loadProfile: const LoadProfile(
          virtualUsers: 1,
          durationSeconds: 1,
        ),
        agents: const [
          RemoteAgent(
            id: 'agent-1',
            machineId: 'machine-1',
            endpoint: 'ws://agent-1',
            version: '1.0.0',
            protocolVersion: '1',
            capacity: RemoteAgentCapacity(
              maxVirtualUsers: 10,
              maxConcurrency: 10,
            ),
            status: RemoteAgentStatus.online,
          ),
        ],
      );

      expect(result.isValid, isFalse);
      expect(
          result.errors.map((issue) => issue.code),
          contains(
            'workflow.start_node_count',
          ));
    });

    test('returns warning for workflow without executable nodes', () {
      final result = validator.validate(
        workflow: Workflow(
          id: 'wf-empty-run',
          name: 'No-op workflow',
          nodes: [
            WorkflowNode(id: 'start', type: 'start', x: 0, y: 0),
            WorkflowNode(id: 'end', type: 'end', x: 100, y: 0),
          ],
          edges: [
            WorkflowEdge(sourceNodeId: 'start', targetNodeId: 'end'),
          ],
        ),
        loadProfile: const LoadProfile(
          virtualUsers: 1,
          durationSeconds: 1,
        ),
        agents: const [
          RemoteAgent(
            id: 'agent-1',
            machineId: 'machine-1',
            endpoint: 'ws://agent-1',
            version: '1.0.0',
            protocolVersion: '1',
            capacity: RemoteAgentCapacity(
              maxVirtualUsers: 10,
              maxConcurrency: 10,
            ),
            status: RemoteAgentStatus.online,
          ),
        ],
      );

      expect(result.isValid, isTrue);
      expect(
          result.warnings.map((issue) => issue.code),
          contains(
            'workflow.no_executable_nodes',
          ));
    });
  });
}

Workflow _workflow() {
  return Workflow(
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
  );
}
