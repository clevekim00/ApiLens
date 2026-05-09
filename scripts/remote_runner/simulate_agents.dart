import 'dart:io';

import 'package:apilens/features/remote_runner/application/agent_registry.dart';
import 'package:apilens/features/remote_runner/application/machine_inventory_service.dart';
import 'package:apilens/features/remote_runner/data/remote_machine_repository.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_agent.dart';

Future<void> main(List<String> args) async {
  final count = args.isNotEmpty ? int.tryParse(args.first) ?? 3 : 3;
  final machineRepository = InMemoryRemoteMachineRepository();
  final inventory = MachineInventoryService(repository: machineRepository);
  final registry = AgentRegistry(machineInventory: inventory);

  for (var i = 1; i <= count; i++) {
    final machineId = 'machine-$i';
    await inventory.addMachine(
      id: machineId,
      name: 'Fake generator $i',
      host: '127.0.0.$i',
      labels: const ['fake', 'local'],
    );
    await registry.register(AgentRegistration(
      id: 'agent-$i',
      machineId: machineId,
      endpoint: 'memory://agent-$i',
      version: '1.0.0',
      protocolVersion: '1',
      supportedNodeTypes: const ['api', 'gql_request', 'ws_connect'],
      capacity: RemoteAgentCapacity(
        maxVirtualUsers: 100 * i,
        maxConcurrency: 25 * i,
      ),
    ));
  }

  stdout.writeln('registered fake agents:');
  for (final agent in registry.agents) {
    stdout.writeln(
      '- ${agent.id} status=${agent.status.name} '
      'vus=${agent.capacity.maxVirtualUsers}',
    );
  }
}
