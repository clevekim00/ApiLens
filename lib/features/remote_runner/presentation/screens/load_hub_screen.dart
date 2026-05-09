import 'package:flutter/material.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../../domain/models/agent_upgrade.dart';
import '../../domain/models/load_profile.dart';
import '../../domain/models/metrics_models.dart';
import '../../domain/models/remote_agent.dart';
import '../../domain/models/remote_machine.dart';
import '../../domain/models/remote_run.dart';
import '../../domain/models/run_shard.dart';
import '../../../workflow_editor/domain/models/workflow.dart';
import '../widgets/agent_update_panel.dart';
import '../widgets/load_hub_summary_bar.dart';
import '../widgets/machine_table.dart';
import '../widgets/metrics_overview.dart';
import '../widgets/run_monitor_panel.dart';

class LoadHubScreen extends StatefulWidget {
  final List<RemoteMachine> machines;
  final List<RemoteAgent> agents;
  final List<RemoteRunPlan> runs;
  final RunMetricsSnapshot metrics;
  final AgentUpgradeRolloutState? upgradeState;

  const LoadHubScreen({
    super.key,
    this.machines = const [],
    this.agents = const [],
    this.runs = const [],
    required this.metrics,
    this.upgradeState,
  });

  factory LoadHubScreen.sample({Key? key}) {
    final now = DateTime.now();
    return LoadHubScreen(
      key: key,
      machines: [
        RemoteMachine(
          id: 'machine-1',
          name: 'Seoul generator 1',
          host: '10.0.0.10',
          platform: 'linux-x64',
          labels: const ['kr', 'staging'],
          adminState: RemoteMachineAdminState.enabled,
          lastSeenAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        RemoteMachine(
          id: 'machine-2',
          name: 'Tokyo generator 1',
          host: '10.0.1.10',
          platform: 'linux-arm64',
          labels: const ['jp'],
          adminState: RemoteMachineAdminState.draining,
          lastSeenAt: now.subtract(const Duration(seconds: 12)),
          createdAt: now,
          updatedAt: now,
        ),
      ],
      agents: const [
        RemoteAgent(
          id: 'agent-1',
          machineId: 'machine-1',
          endpoint: 'ws://10.0.0.10:8787',
          version: '1.0.0',
          protocolVersion: '1',
          capacity:
              RemoteAgentCapacity(maxVirtualUsers: 500, maxConcurrency: 100),
          status: RemoteAgentStatus.online,
        ),
        RemoteAgent(
          id: 'agent-2',
          machineId: 'machine-2',
          endpoint: 'ws://10.0.1.10:8787',
          version: '0.9.0',
          protocolVersion: '1',
          capacity:
              RemoteAgentCapacity(maxVirtualUsers: 300, maxConcurrency: 60),
          status: RemoteAgentStatus.draining,
        ),
      ],
      runs: [
        RemoteRunPlan(
          id: 'run-1-plan',
          draft: RemoteRunDraft(
            id: 'run-1',
            workflowSnapshot: _emptyWorkflow(),
            loadProfile: const LoadProfile(
              virtualUsers: 500,
              durationSeconds: 60,
            ),
            createdAt: now,
          ),
          shards: const [
            RunShard(
              id: 'run-1-shard-001',
              runId: 'run-1',
              agentId: 'agent-1',
              virtualUserRange:
                  VirtualUserRange(startInclusive: 1, endInclusive: 250),
              rampUpOffsetMs: 0,
              durationSeconds: 60,
              concurrencyLimit: 100,
              status: RunShardStatus.running,
            ),
          ],
          status: RemoteRunStatus.running,
          plannedAt: now,
        ),
      ],
      metrics: RunMetricsSnapshot(
        runId: 'run-1',
        requestCount: 24800,
        errorCount: 31,
        updatedAt: now,
      ),
      upgradeState: AgentUpgradeRolloutState(
        planId: 'upgrade-1',
        machineStatuses: const {
          'machine-1': AgentUpgradeMachineStatus.completed,
          'machine-2': AgentUpgradeMachineStatus.draining,
        },
        startedAt: now.subtract(const Duration(minutes: 2)),
      ),
    );
  }

  @override
  State<LoadHubScreen> createState() => _LoadHubScreenState();
}

class _LoadHubScreenState extends State<LoadHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(AppTokens.s5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              machineCount: widget.machines.length,
              agentCount: widget.agents.length,
            ),
            const SizedBox(height: AppTokens.s4),
            LoadHubSummaryBar(
              machines: widget.machines,
              agents: widget.agents,
              runs: widget.runs,
              metrics: widget.metrics,
            ),
            const SizedBox(height: AppTokens.s4),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Machines'),
                Tab(text: 'Runs'),
                Tab(text: 'Metrics'),
                Tab(text: 'Logs'),
                Tab(text: 'Agent Updates'),
              ],
            ),
            const SizedBox(height: AppTokens.s4),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  MachineTable(
                      machines: widget.machines, agents: widget.agents),
                  RunMonitorPanel(runs: widget.runs),
                  MetricsOverview(metrics: widget.metrics),
                  const _LogsPanel(),
                  AgentUpdatePanel(state: widget.upgradeState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int machineCount;
  final int agentCount;

  const _Header({
    required this.machineCount,
    required this.agentCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(Icons.hub_outlined, size: 28),
        const SizedBox(width: AppTokens.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Load Hub',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '원격 머신 $machineCount대, 원격 에이전트 $agentCount개',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogsPanel extends StatelessWidget {
  const _LogsPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        Text('최근 경고와 오류 로그', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTokens.s3),
        const _LogLine(level: 'WARN', message: 'agent-2 drain 진행 중'),
        const _LogLine(level: 'INFO', message: 'run-1 metric window 수신'),
      ],
    );
  }
}

class _LogLine extends StatelessWidget {
  final String level;
  final String message;

  const _LogLine({
    required this.level,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s2),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text(level)),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

Workflow _emptyWorkflow() {
  return Workflow(
    id: 'sample-workflow',
    name: 'Sample Load Workflow',
    nodes: const [],
    edges: const [],
  );
}
