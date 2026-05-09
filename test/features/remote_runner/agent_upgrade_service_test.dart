import 'package:apilens/features/remote_runner/application/agent_upgrade_service.dart';
import 'package:apilens/features/remote_runner/domain/models/agent_upgrade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentUpgradeService', () {
    test('runs staged upgrade successfully', () async {
      final executor = FakeAgentUpgradeExecutor();
      final service = AgentUpgradeService(
        executor: executor,
        now: () => DateTime.utc(2026, 5, 9, 12),
      );

      final state = await service.run(_plan(
        machineIds: const ['machine-1', 'machine-2'],
        batchSize: 1,
      ));

      expect(state.isFinished, isTrue);
      expect(state.machineStatuses['machine-1'],
          AgentUpgradeMachineStatus.completed);
      expect(state.machineStatuses['machine-2'],
          AgentUpgradeMachineStatus.completed);
      expect(
          executor.calls,
          containsAllInOrder([
            'drain:machine-1',
            'install:machine-1:2.0.0',
            'restart:machine-1',
            'health:machine-1',
            'drain:machine-2',
          ]));
    });

    test('rolls back when health check fails and rollback package exists',
        () async {
      final executor = FakeAgentUpgradeExecutor(
        unhealthyMachines: const {'machine-1'},
      );
      final service = AgentUpgradeService(executor: executor);

      final state = await service.run(_plan(machineIds: const ['machine-1']));

      expect(state.machineStatuses['machine-1'],
          AgentUpgradeMachineStatus.rolledBack);
      expect(executor.calls, contains('rollback:machine-1'));
      expect(executor.disabledMachines, isEmpty);
    });

    test('disables scheduling when rollback fails', () async {
      final executor = FakeAgentUpgradeExecutor(
        unhealthyMachines: const {'machine-1'},
        rollbackFailureMachines: const {'machine-1'},
      );
      final service = AgentUpgradeService(executor: executor);

      final state = await service.run(_plan(machineIds: const ['machine-1']));

      expect(
          state.machineStatuses['machine-1'], AgentUpgradeMachineStatus.failed);
      expect(executor.disabledMachines, contains('machine-1'));
    });

    test('force upgrade skips drain', () async {
      final executor = FakeAgentUpgradeExecutor();
      final service = AgentUpgradeService(executor: executor);

      await service.run(_plan(
        machineIds: const ['machine-1'],
        force: true,
      ));

      expect(executor.calls, isNot(contains('drain:machine-1')));
      expect(executor.calls.first, 'install:machine-1:2.0.0');
    });
  });
}

AgentUpgradePlan _plan({
  required List<String> machineIds,
  int batchSize = 1,
  bool force = false,
}) {
  return AgentUpgradePlan(
    id: 'upgrade-1',
    machineIds: machineIds,
    targetVersion: const AgentVersionManifest(
      version: '2.0.0',
      protocolVersion: '1',
      packageUrl: 'https://example.test/agent.tar.gz',
      checksum: 'sha256:abc',
      rollbackPackageUrl: 'https://example.test/agent-1.tar.gz',
    ),
    batchSize: batchSize,
    drainTimeoutSeconds: 30,
    force: force,
  );
}
