import 'package:flutter/material.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../../domain/models/metrics_models.dart';
import '../../domain/models/remote_agent.dart';
import '../../domain/models/remote_machine.dart';
import '../../domain/models/remote_run.dart';

class LoadHubSummaryBar extends StatelessWidget {
  final List<RemoteMachine> machines;
  final List<RemoteAgent> agents;
  final List<RemoteRunPlan> runs;
  final RunMetricsSnapshot metrics;

  const LoadHubSummaryBar({
    super.key,
    required this.machines,
    required this.agents,
    required this.runs,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final onlineAgents = agents
        .where((agent) => agent.status == RemoteAgentStatus.online)
        .length;
    final activeRuns =
        runs.where((run) => run.status == RemoteRunStatus.running).length;
    final errorRate = (metrics.errorRate * 100).toStringAsFixed(2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final cards = [
          _SummaryTile(
            label: 'Machines',
            value: '${machines.length}',
            icon: Icons.dns_outlined,
          ),
          _SummaryTile(
            label: 'Online Agents',
            value: '$onlineAgents/${agents.length}',
            icon: Icons.sensors_outlined,
          ),
          _SummaryTile(
            label: 'Active Runs',
            value: '$activeRuns',
            icon: Icons.play_circle_outline,
          ),
          _SummaryTile(
            label: 'Error Rate',
            value: '$errorRate%',
            icon: Icons.error_outline,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (final card in cards) ...[
                Expanded(child: card),
                if (card != cards.last) const SizedBox(width: AppTokens.s3),
              ],
            ],
          );
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppTokens.s3,
          mainAxisSpacing: AppTokens.s3,
          childAspectRatio: 2.15,
          children: cards,
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppTokens.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
