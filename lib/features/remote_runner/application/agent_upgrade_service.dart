import '../domain/models/agent_upgrade.dart';

abstract class AgentUpgradeExecutor {
  Future<void> drain(String machineId, Duration timeout);
  Future<void> install(String machineId, AgentVersionManifest targetVersion);
  Future<void> restart(String machineId);
  Future<bool> healthCheck(String machineId);
  Future<void> rollback(String machineId, AgentVersionManifest targetVersion);
  Future<void> disableScheduling(String machineId);
}

class AgentUpgradeService {
  final AgentUpgradeExecutor _executor;
  final DateTime Function() _now;

  AgentUpgradeService({
    required AgentUpgradeExecutor executor,
    DateTime Function()? now,
  })  : _executor = executor,
        _now = now ?? DateTime.now;

  Future<AgentUpgradeRolloutState> run(AgentUpgradePlan plan) async {
    var state = AgentUpgradeRolloutState(
      planId: plan.id,
      machineStatuses: {
        for (final machineId in plan.machineIds)
          machineId: AgentUpgradeMachineStatus.pending,
      },
      startedAt: _now(),
    );

    final failures = <String>[];
    for (final batch in _batches(plan.machineIds, plan.batchSize)) {
      for (final machineId in batch) {
        state = await _upgradeMachine(plan, state, machineId, failures);
      }
    }

    return state.copyWith(
      finishedAt: _now(),
      message: failures.isEmpty
          ? '모든 에이전트 업그레이드가 완료되었습니다.'
          : '일부 에이전트 업그레이드가 실패했습니다: ${failures.join(', ')}',
    );
  }

  Future<AgentUpgradeRolloutState> _upgradeMachine(
    AgentUpgradePlan plan,
    AgentUpgradeRolloutState state,
    String machineId,
    List<String> failures,
  ) async {
    try {
      if (!plan.force) {
        state = _setStatus(
          state,
          machineId,
          AgentUpgradeMachineStatus.draining,
        );
        await _executor.drain(
          machineId,
          Duration(seconds: plan.drainTimeoutSeconds),
        );
      }

      state = _setStatus(
        state,
        machineId,
        AgentUpgradeMachineStatus.installing,
      );
      await _executor.install(machineId, plan.targetVersion);

      state = _setStatus(
        state,
        machineId,
        AgentUpgradeMachineStatus.restarting,
      );
      await _executor.restart(machineId);

      state = _setStatus(
        state,
        machineId,
        AgentUpgradeMachineStatus.healthChecking,
      );
      final healthy = await _executor.healthCheck(machineId);
      if (healthy) {
        return _setStatus(
          state,
          machineId,
          AgentUpgradeMachineStatus.completed,
        );
      }

      if (plan.rollbackOnHealthCheckFailure &&
          plan.targetVersion.rollbackPackageUrl != null) {
        state = _setStatus(
          state,
          machineId,
          AgentUpgradeMachineStatus.rollingBack,
        );
        await _executor.rollback(machineId, plan.targetVersion);
        return _setStatus(
          state,
          machineId,
          AgentUpgradeMachineStatus.rolledBack,
        );
      }

      await _executor.disableScheduling(machineId);
      failures.add(machineId);
      return _setStatus(state, machineId, AgentUpgradeMachineStatus.failed);
    } catch (_) {
      failures.add(machineId);
      await _safeDisableScheduling(machineId);
      return _setStatus(state, machineId, AgentUpgradeMachineStatus.failed);
    }
  }

  Future<void> _safeDisableScheduling(String machineId) async {
    try {
      await _executor.disableScheduling(machineId);
    } catch (_) {
      // Best-effort safety fallback.
    }
  }

  AgentUpgradeRolloutState _setStatus(
    AgentUpgradeRolloutState state,
    String machineId,
    AgentUpgradeMachineStatus status,
  ) {
    return state.copyWith(
      machineStatuses: {
        ...state.machineStatuses,
        machineId: status,
      },
    );
  }

  List<List<String>> _batches(List<String> machineIds, int batchSize) {
    final size = batchSize <= 0 ? 1 : batchSize;
    final batches = <List<String>>[];
    for (var index = 0; index < machineIds.length; index += size) {
      final end =
          index + size > machineIds.length ? machineIds.length : index + size;
      batches.add(machineIds.sublist(index, end));
    }
    return batches;
  }
}

class FakeAgentUpgradeExecutor implements AgentUpgradeExecutor {
  final Set<String> unhealthyMachines;
  final Set<String> installFailureMachines;
  final Set<String> rollbackFailureMachines;
  final List<String> calls = [];
  final Set<String> disabledMachines = {};

  FakeAgentUpgradeExecutor({
    this.unhealthyMachines = const {},
    this.installFailureMachines = const {},
    this.rollbackFailureMachines = const {},
  });

  @override
  Future<void> drain(String machineId, Duration timeout) async {
    calls.add('drain:$machineId');
  }

  @override
  Future<void> install(
    String machineId,
    AgentVersionManifest targetVersion,
  ) async {
    calls.add('install:$machineId:${targetVersion.version}');
    if (installFailureMachines.contains(machineId)) {
      throw StateError('install failed');
    }
  }

  @override
  Future<void> restart(String machineId) async {
    calls.add('restart:$machineId');
  }

  @override
  Future<bool> healthCheck(String machineId) async {
    calls.add('health:$machineId');
    return !unhealthyMachines.contains(machineId);
  }

  @override
  Future<void> rollback(
    String machineId,
    AgentVersionManifest targetVersion,
  ) async {
    calls.add('rollback:$machineId');
    if (rollbackFailureMachines.contains(machineId)) {
      throw StateError('rollback failed');
    }
  }

  @override
  Future<void> disableScheduling(String machineId) async {
    calls.add('disable:$machineId');
    disabledMachines.add(machineId);
  }
}
