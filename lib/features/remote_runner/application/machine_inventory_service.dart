import '../data/remote_machine_repository.dart';
import '../domain/models/remote_machine.dart';

typedef DateTimeProvider = DateTime Function();

class MachineInventoryService {
  final RemoteMachineRepository _repository;
  final DateTimeProvider _now;

  MachineInventoryService({
    required RemoteMachineRepository repository,
    DateTimeProvider? now,
  })  : _repository = repository,
        _now = now ?? DateTime.now;

  Future<List<RemoteMachine>> getAll() {
    return _repository.getAll();
  }

  Future<RemoteMachine?> getById(String id) {
    return _repository.getById(id);
  }

  Future<RemoteMachine> addMachine({
    required String id,
    required String name,
    required String host,
    String platform = 'unknown',
    List<String> labels = const [],
    String? credentialRef,
    String? agentInstallPath,
  }) async {
    final now = _now();
    final machine = RemoteMachine(
      id: id,
      name: name,
      host: host,
      platform: platform,
      labels: labels,
      credentialRef: credentialRef,
      agentInstallPath: agentInstallPath,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.save(machine);
    return machine;
  }

  Future<RemoteMachine> updateMachine(RemoteMachine machine) async {
    final updated = machine.copyWith(updatedAt: _now());
    await _repository.save(updated);
    return updated;
  }

  Future<RemoteMachine> setAdminState(
    String machineId,
    RemoteMachineAdminState state,
  ) async {
    final machine = await _requireMachine(machineId);
    final updated = machine.copyWith(
      adminState: state,
      updatedAt: _now(),
    );
    await _repository.save(updated);
    return updated;
  }

  Future<RemoteMachine> setLabels(
    String machineId,
    List<String> labels,
  ) async {
    final machine = await _requireMachine(machineId);
    final updated = machine.copyWith(
      labels: labels,
      updatedAt: _now(),
    );
    await _repository.save(updated);
    return updated;
  }

  Future<void> deleteMachine(String machineId) {
    return _repository.delete(machineId);
  }

  Future<RemoteMachine> markSeen(String machineId) async {
    final machine = await _requireMachine(machineId);
    final now = _now();
    final updated = machine.copyWith(
      lastSeenAt: now,
      updatedAt: now,
    );
    await _repository.save(updated);
    return updated;
  }

  Future<RemoteMachine> _requireMachine(String machineId) async {
    final machine = await _repository.getById(machineId);
    if (machine == null) {
      throw StateError('원격 머신을 찾을 수 없습니다: $machineId');
    }
    return machine;
  }
}
