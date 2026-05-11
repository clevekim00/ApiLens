import 'machine_resource_snapshot.dart';

enum RemoteAgentStatus {
  unknown,
  online,
  busy,
  draining,
  disabled,
  offline,
  incompatible,
  upgradeRequired,
}

class RemoteAgentCapacity {
  final int maxVirtualUsers;
  final int maxConcurrency;
  final int weight;

  const RemoteAgentCapacity({
    required this.maxVirtualUsers,
    required this.maxConcurrency,
    this.weight = 1,
  });

  bool get canRunLoad => maxVirtualUsers > 0 && maxConcurrency > 0;

  Map<String, dynamic> toJson() => {
        'maxVirtualUsers': maxVirtualUsers,
        'maxConcurrency': maxConcurrency,
        'weight': weight,
      };

  factory RemoteAgentCapacity.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RemoteAgentCapacity(maxVirtualUsers: 0, maxConcurrency: 0);
    }
    return RemoteAgentCapacity(
      maxVirtualUsers: (json['maxVirtualUsers'] as num?)?.toInt() ?? 0,
      maxConcurrency: (json['maxConcurrency'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toInt() ?? 1,
    );
  }
}

class RemoteAgent {
  final String id;
  final String machineId;
  final String endpoint;
  final String version;
  final String protocolVersion;
  final List<String> tags;
  final List<String> supportedNodeTypes;
  final RemoteAgentCapacity capacity;
  final RemoteAgentStatus status;
  final DateTime? lastHeartbeatAt;
  final String? statusMessage;
  final MachineResourceSnapshot? resourceSnapshot;

  const RemoteAgent({
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
    this.status = RemoteAgentStatus.unknown,
    this.lastHeartbeatAt,
    this.statusMessage,
    this.resourceSnapshot,
  });

  bool supportsNodeType(String type) {
    return supportedNodeTypes.isEmpty || supportedNodeTypes.contains(type);
  }

  bool get isSchedulable {
    return status == RemoteAgentStatus.online && capacity.canRunLoad;
  }

  RemoteAgent copyWith({
    String? id,
    String? machineId,
    String? endpoint,
    String? version,
    String? protocolVersion,
    List<String>? tags,
    List<String>? supportedNodeTypes,
    RemoteAgentCapacity? capacity,
    RemoteAgentStatus? status,
    DateTime? lastHeartbeatAt,
    String? statusMessage,
    MachineResourceSnapshot? resourceSnapshot,
  }) {
    return RemoteAgent(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      endpoint: endpoint ?? this.endpoint,
      version: version ?? this.version,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      tags: tags ?? this.tags,
      supportedNodeTypes: supportedNodeTypes ?? this.supportedNodeTypes,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
      statusMessage: statusMessage ?? this.statusMessage,
      resourceSnapshot: resourceSnapshot ?? this.resourceSnapshot,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'machineId': machineId,
        'endpoint': endpoint,
        'version': version,
        'protocolVersion': protocolVersion,
        'tags': tags,
        'supportedNodeTypes': supportedNodeTypes,
        'capacity': capacity.toJson(),
        'status': status.name,
        'lastHeartbeatAt': lastHeartbeatAt?.toIso8601String(),
        'statusMessage': statusMessage,
        'resourceSnapshot': resourceSnapshot?.toJson(),
      };

  factory RemoteAgent.fromJson(Map<String, dynamic> json) {
    return RemoteAgent(
      id: json['id'] as String? ?? '',
      machineId: json['machineId'] as String? ?? '',
      endpoint: json['endpoint'] as String? ?? '',
      version: json['version'] as String? ?? '0.0.0',
      protocolVersion: json['protocolVersion'] as String? ?? '1',
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      supportedNodeTypes:
          (json['supportedNodeTypes'] as List?)?.cast<String>() ?? const [],
      capacity: RemoteAgentCapacity.fromJson(
        json['capacity'] is Map
            ? Map<String, dynamic>.from(json['capacity'] as Map)
            : null,
      ),
      status: RemoteAgentStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RemoteAgentStatus.unknown,
      ),
      lastHeartbeatAt: json['lastHeartbeatAt'] != null
          ? DateTime.tryParse(json['lastHeartbeatAt'] as String)
          : null,
      statusMessage: json['statusMessage'] as String?,
      resourceSnapshot: json['resourceSnapshot'] == null
          ? null
          : MachineResourceSnapshot.fromJson(
              json['resourceSnapshot'] is Map
                  ? Map<String, dynamic>.from(json['resourceSnapshot'] as Map)
                  : null,
            ),
    );
  }
}
