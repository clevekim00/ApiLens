import '../domain/models/remote_agent.dart';
import '../domain/models/remote_machine.dart';
import 'machine_inventory_service.dart';

class AgentRegistration {
  final String id;
  final String machineId;
  final String endpoint;
  final String version;
  final String protocolVersion;
  final List<String> tags;
  final List<String> supportedNodeTypes;
  final RemoteAgentCapacity capacity;

  const AgentRegistration({
    required this.id,
    required this.machineId,
    required this.endpoint,
    required this.version,
    required this.protocolVersion,
    this.tags = const [],
    this.supportedNodeTypes = const [],
    this.capacity = const RemoteAgentCapacity(
      maxVirtualUsers: 0,
      maxConcurrency: 0,
    ),
  });
}

class AgentRegistry {
  final MachineInventoryService _machineInventory;
  final DateTimeProvider _now;
  final Duration heartbeatTimeout;
  final Map<String, RemoteAgent> _agents = {};

  AgentRegistry({
    required MachineInventoryService machineInventory,
    this.heartbeatTimeout = const Duration(seconds: 30),
    DateTimeProvider? now,
  })  : _machineInventory = machineInventory,
        _now = now ?? DateTime.now;

  List<RemoteAgent> get agents {
    return _agents.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  RemoteAgent? getById(String id) {
    return _agents[id];
  }

  Future<RemoteAgent> register(AgentRegistration registration) async {
    final machine = await _machineInventory.getById(registration.machineId);
    final now = _now();
    final status = _statusForMachine(machine);

    if (machine != null) {
      await _machineInventory.markSeen(machine.id);
    }

    final agent = RemoteAgent(
      id: registration.id,
      machineId: registration.machineId,
      endpoint: registration.endpoint,
      version: registration.version,
      protocolVersion: registration.protocolVersion,
      tags: registration.tags,
      supportedNodeTypes: registration.supportedNodeTypes,
      capacity: registration.capacity,
      status: status,
      lastHeartbeatAt: now,
      statusMessage: machine == null ? '등록되지 않은 원격 머신입니다.' : null,
    );
    _agents[agent.id] = agent;
    return agent;
  }

  RemoteAgent heartbeat(
    String agentId, {
    RemoteAgentCapacity? capacity,
    RemoteAgentStatus? status,
    String? statusMessage,
  }) {
    final agent = _requireAgent(agentId);
    final nextStatus = status ?? _heartbeatStatus(agent);
    final updated = agent.copyWith(
      capacity: capacity,
      status: nextStatus,
      lastHeartbeatAt: _now(),
      statusMessage: statusMessage,
    );
    _agents[agentId] = updated;
    return updated;
  }

  RemoteAgent setStatus(
    String agentId,
    RemoteAgentStatus status, {
    String? statusMessage,
  }) {
    final agent = _requireAgent(agentId);
    final updated = agent.copyWith(
      status: status,
      statusMessage: statusMessage,
    );
    _agents[agentId] = updated;
    return updated;
  }

  List<RemoteAgent> expireHeartbeats() {
    final now = _now();
    final updatedAgents = <RemoteAgent>[];
    for (final entry in _agents.entries) {
      final agent = entry.value;
      final lastHeartbeatAt = agent.lastHeartbeatAt;
      if (lastHeartbeatAt == null ||
          now.difference(lastHeartbeatAt) <= heartbeatTimeout ||
          agent.status == RemoteAgentStatus.offline) {
        continue;
      }

      final updated = agent.copyWith(
        status: RemoteAgentStatus.offline,
        statusMessage: 'heartbeat timeout',
      );
      _agents[entry.key] = updated;
      updatedAgents.add(updated);
    }
    return updatedAgents;
  }

  List<RemoteAgent> schedulableAgents({
    Iterable<String> requiredNodeTypes = const [],
  }) {
    final types = requiredNodeTypes.toSet();
    return agents.where((agent) {
      if (!agent.isSchedulable) return false;
      if (types.isEmpty) return true;
      return types.every(agent.supportsNodeType);
    }).toList();
  }

  RemoteAgent _requireAgent(String agentId) {
    final agent = _agents[agentId];
    if (agent == null) {
      throw StateError('원격 에이전트를 찾을 수 없습니다: $agentId');
    }
    return agent;
  }

  RemoteAgentStatus _statusForMachine(RemoteMachine? machine) {
    if (machine == null) return RemoteAgentStatus.incompatible;
    switch (machine.adminState) {
      case RemoteMachineAdminState.enabled:
        return RemoteAgentStatus.online;
      case RemoteMachineAdminState.disabled:
        return RemoteAgentStatus.disabled;
      case RemoteMachineAdminState.draining:
        return RemoteAgentStatus.draining;
    }
  }

  RemoteAgentStatus _heartbeatStatus(RemoteAgent agent) {
    if (agent.status == RemoteAgentStatus.disabled ||
        agent.status == RemoteAgentStatus.draining ||
        agent.status == RemoteAgentStatus.incompatible) {
      return agent.status;
    }
    return RemoteAgentStatus.online;
  }
}
