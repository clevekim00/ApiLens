import 'package:flutter/material.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../../domain/models/remote_agent.dart';
import '../../domain/models/remote_machine.dart';

class MachineHealthPanel extends StatelessWidget {
  final List<RemoteMachine> machines;
  final List<RemoteAgent> agents;

  const MachineHealthPanel({
    super.key,
    required this.machines,
    required this.agents,
  });

  @override
  Widget build(BuildContext context) {
    final rows = machines.map((machine) {
      final agent =
          agents.where((item) => item.machineId == machine.id).firstOrNull;
      return _MachineHealthRow(machine: machine, agent: agent);
    }).toList();

    if (rows.isEmpty) {
      return const Center(child: Text('수집된 머신 상태가 없습니다.'));
    }

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s3),
      itemBuilder: (context, index) => rows[index],
    );
  }
}

class _MachineHealthRow extends StatelessWidget {
  final RemoteMachine machine;
  final RemoteAgent? agent;

  const _MachineHealthRow({
    required this.machine,
    required this.agent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = agent?.resourceSnapshot;

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
              Icon(
                snapshot?.isUnderPressure == true
                    ? Icons.warning_amber_outlined
                    : Icons.monitor_heart_outlined,
                size: 18,
                color: snapshot?.isUnderPressure == true
                    ? Colors.orange.shade600
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTokens.s2),
              Expanded(
                child: Text(
                  '${machine.name} - ${machine.host}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                agent?.id ?? 'no agent',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s3),
          if (snapshot == null)
            Text(
              '아직 리소스 heartbeat가 수신되지 않았습니다.',
              style: theme.textTheme.bodyMedium,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 760 ? 2 : 4;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  mainAxisSpacing: AppTokens.s2,
                  crossAxisSpacing: AppTokens.s2,
                  childAspectRatio: columns == 2 ? 2.6 : 2.2,
                  children: [
                    _MetricTile(
                      label: 'CPU',
                      value: '${snapshot.cpuUsagePercent.toStringAsFixed(1)}%',
                    ),
                    _MetricTile(
                      label: 'Memory',
                      value:
                          '${snapshot.memoryUsagePercent.toStringAsFixed(1)}%',
                      detail:
                          '${_formatBytes(snapshot.memoryUsedBytes)} / ${_formatBytes(snapshot.memoryTotalBytes)}',
                    ),
                    _MetricTile(
                      label: 'Disk I/O',
                      value:
                          '${_formatBytes(snapshot.diskReadBytesPerSecond.round())}/s R',
                      detail:
                          '${_formatBytes(snapshot.diskWriteBytesPerSecond.round())}/s W',
                    ),
                    _MetricTile(
                      label: 'Network',
                      value:
                          '${_formatBytes(snapshot.networkRxBytesPerSecond.round())}/s RX',
                      detail:
                          '${_formatBytes(snapshot.networkTxBytesPerSecond.round())}/s TX',
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;

  const _MetricTile({
    required this.label,
    required this.value,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatBytes(num bytes) {
  final value = bytes.toDouble();
  if (value >= 1024 * 1024 * 1024) {
    return '${(value / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
  if (value >= 1024 * 1024) {
    return '${(value / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  if (value >= 1024) {
    return '${(value / 1024).toStringAsFixed(1)} KB';
  }
  return '${value.toStringAsFixed(0)} B';
}
