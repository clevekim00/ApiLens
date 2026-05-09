import 'package:apilens/features/remote_runner/application/agent_registry.dart';
import 'package:apilens/features/remote_runner/application/machine_inventory_service.dart';
import 'package:apilens/features/remote_runner/data/remote_machine_repository.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_agent.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_machine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MachineInventoryService', () {
    test('adds and updates remote machines', () async {
      var now = DateTime.utc(2026, 5, 9, 12);
      final service = MachineInventoryService(
        repository: InMemoryRemoteMachineRepository(),
        now: () => now,
      );

      final machine = await service.addMachine(
        id: 'machine-1',
        name: 'Load generator 1',
        host: '10.0.0.10',
        labels: const ['staging'],
      );

      expect(machine.adminState, RemoteMachineAdminState.enabled);
      expect(machine.isSchedulable, isTrue);

      now = now.add(const Duration(minutes: 1));
      final disabled = await service.setAdminState(
        machine.id,
        RemoteMachineAdminState.disabled,
      );

      expect(disabled.adminState, RemoteMachineAdminState.disabled);
      expect(disabled.isSchedulable, isFalse);
      expect(disabled.updatedAt, now);
    });
  });

  group('AgentRegistry', () {
    late DateTime now;
    late MachineInventoryService machineInventory;
    late AgentRegistry registry;

    setUp(() async {
      now = DateTime.utc(2026, 5, 9, 12);
      machineInventory = MachineInventoryService(
        repository: InMemoryRemoteMachineRepository(),
        now: () => now,
      );
      await machineInventory.addMachine(
        id: 'machine-1',
        name: 'Load generator 1',
        host: '10.0.0.10',
      );
      registry = AgentRegistry(
        machineInventory: machineInventory,
        heartbeatTimeout: const Duration(seconds: 10),
        now: () => now,
      );
    });

    test('registers agent as online when machine is enabled', () async {
      final agent = await registry.register(_registration());

      expect(agent.status, RemoteAgentStatus.online);
      expect(agent.lastHeartbeatAt, now);
      expect(registry.schedulableAgents().map((agent) => agent.id), [
        'agent-1',
      ]);
    });

    test('expires heartbeat after timeout', () async {
      await registry.register(_registration());

      now = now.add(const Duration(seconds: 11));
      final expired = registry.expireHeartbeats();

      expect(expired, hasLength(1));
      expect(expired.single.status, RemoteAgentStatus.offline);
      expect(registry.schedulableAgents(), isEmpty);
    });

    test('heartbeat keeps existing draining status', () async {
      await registry.register(_registration());
      registry.setStatus('agent-1', RemoteAgentStatus.draining);

      now = now.add(const Duration(seconds: 3));
      final updated = registry.heartbeat('agent-1');

      expect(updated.status, RemoteAgentStatus.draining);
      expect(registry.schedulableAgents(), isEmpty);
    });

    test('disabled machine registers agent as disabled', () async {
      await machineInventory.setAdminState(
        'machine-1',
        RemoteMachineAdminState.disabled,
      );

      final agent = await registry.register(_registration());

      expect(agent.status, RemoteAgentStatus.disabled);
      expect(registry.schedulableAgents(), isEmpty);
    });

    test('filters schedulable agents by supported node types', () async {
      await registry.register(_registration(
        supportedNodeTypes: const ['api'],
      ));

      expect(
        registry.schedulableAgents(requiredNodeTypes: const ['api']),
        hasLength(1),
      );
      expect(
        registry.schedulableAgents(requiredNodeTypes: const ['ws_connect']),
        isEmpty,
      );
    });
  });
}

AgentRegistration _registration({
  List<String> supportedNodeTypes = const ['api', 'gql_request'],
}) {
  return AgentRegistration(
    id: 'agent-1',
    machineId: 'machine-1',
    endpoint: 'ws://10.0.0.10:8787',
    version: '1.0.0',
    protocolVersion: '1',
    supportedNodeTypes: supportedNodeTypes,
    capacity: const RemoteAgentCapacity(
      maxVirtualUsers: 100,
      maxConcurrency: 20,
    ),
  );
}
