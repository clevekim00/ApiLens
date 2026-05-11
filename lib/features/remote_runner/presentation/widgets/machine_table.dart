import 'package:flutter/material.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../../domain/models/remote_agent.dart';
import '../../domain/models/remote_machine.dart';

class MachineTable extends StatelessWidget {
  final List<RemoteMachine> machines;
  final List<RemoteAgent> agents;

  const MachineTable({
    super.key,
    required this.machines,
    required this.agents,
  });

  @override
  Widget build(BuildContext context) {
    if (machines.isEmpty) {
      return const Center(child: Text('등록된 원격 머신이 없습니다.'));
    }

    return ListView.separated(
      itemCount: machines.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s2),
      itemBuilder: (context, index) {
        final machine = machines[index];
        final agent =
            agents.where((a) => a.machineId == machine.id).firstOrNull;
        return _MachineRow(machine: machine, agent: agent);
      },
    );
  }
}

class _MachineRow extends StatelessWidget {
  final RemoteMachine machine;
  final RemoteAgent? agent;

  const _MachineRow({
    required this.machine,
    required this.agent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 680;
          final status = agent?.status.name ?? 'noAgent';
          final version = agent?.version ?? '-';
          final capacity = agent == null
              ? '-'
              : '${agent!.capacity.maxVirtualUsers} VU / '
                  '${agent!.capacity.maxConcurrency} C';
          final resources = agent?.resourceSnapshot;
          final cpu = resources == null
              ? '-'
              : '${resources.cpuUsagePercent.toStringAsFixed(0)}%';
          final memory = resources == null
              ? '-'
              : '${resources.memoryUsagePercent.toStringAsFixed(0)}%';

          final cells = [
            _Cell(label: 'Machine', value: machine.name),
            _Cell(label: 'Host', value: machine.host),
            _Cell(label: 'Agent', value: status),
            _Cell(label: 'Version', value: version),
            _Cell(label: 'Capacity', value: capacity),
            _Cell(label: 'CPU', value: cpu),
            _Cell(label: 'Memory', value: memory),
            _Cell(label: 'Admin', value: machine.adminState.name),
          ];

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cells,
            );
          }

          return Row(
            children: [
              for (final cell in cells) Expanded(child: cell),
            ],
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;

  const _Cell({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppTokens.s3, bottom: AppTokens.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
