import '../domain/models/remote_machine.dart';

abstract class RemoteMachineRepository {
  Future<List<RemoteMachine>> getAll();
  Future<RemoteMachine?> getById(String id);
  Future<void> save(RemoteMachine machine);
  Future<void> delete(String id);
}

class InMemoryRemoteMachineRepository implements RemoteMachineRepository {
  final Map<String, RemoteMachine> _machines = {};

  @override
  Future<List<RemoteMachine>> getAll() async {
    return _machines.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<RemoteMachine?> getById(String id) async {
    return _machines[id];
  }

  @override
  Future<void> save(RemoteMachine machine) async {
    _machines[machine.id] = machine;
  }

  @override
  Future<void> delete(String id) async {
    _machines.remove(id);
  }
}
