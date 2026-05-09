import 'package:flutter/material.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../../domain/models/agent_upgrade.dart';

class AgentUpdatePanel extends StatelessWidget {
  final AgentUpgradeRolloutState? state;

  const AgentUpdatePanel({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final rollout = state;
    if (rollout == null) {
      return const Center(child: Text('진행 중인 에이전트 업데이트가 없습니다.'));
    }

    return ListView(
      children: [
        Text(
          'Rollout ${rollout.planId}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppTokens.s3),
        for (final entry in rollout.machineStatuses.entries)
          _UpgradeRow(machineId: entry.key, status: entry.value),
      ],
    );
  }
}

class _UpgradeRow extends StatelessWidget {
  final String machineId;
  final AgentUpgradeMachineStatus status;

  const _UpgradeRow({
    required this.machineId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.s2),
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(child: Text(machineId)),
          Text(status.name),
        ],
      ),
    );
  }
}
