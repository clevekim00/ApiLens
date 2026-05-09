import 'package:flutter/material.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../../domain/models/remote_run.dart';
import '../../domain/models/run_shard.dart';

class RunMonitorPanel extends StatelessWidget {
  final List<RemoteRunPlan> runs;

  const RunMonitorPanel({
    super.key,
    required this.runs,
  });

  @override
  Widget build(BuildContext context) {
    if (runs.isEmpty) {
      return const Center(child: Text('실행 중인 분산 run이 없습니다.'));
    }

    return ListView.separated(
      itemCount: runs.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s3),
      itemBuilder: (context, index) => _RunRow(run: runs[index]),
    );
  }
}

class _RunRow extends StatelessWidget {
  final RemoteRunPlan run;

  const _RunRow({required this.run});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running = run.shards
        .where((shard) => shard.status == RunShardStatus.running)
        .length;
    final completed = run.shards
        .where((shard) => shard.status == RunShardStatus.completed)
        .length;

    return Container(
      padding: const EdgeInsets.all(AppTokens.s4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  run.draft.workflowSnapshot.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusPill(label: run.status.name),
            ],
          ),
          const SizedBox(height: AppTokens.s3),
          Wrap(
            spacing: AppTokens.s4,
            runSpacing: AppTokens.s2,
            children: [
              Text('Run ID: ${run.draft.id}'),
              Text('Shards: ${run.shards.length}'),
              Text('Running: $running'),
              Text('Completed: $completed'),
              Text('VU: ${run.draft.loadProfile.virtualUsers}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppTokens.s2, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
