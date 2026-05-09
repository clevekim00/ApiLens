enum AgentUpgradeMachineStatus {
  pending,
  draining,
  installing,
  restarting,
  healthChecking,
  completed,
  skipped,
  rollingBack,
  rolledBack,
  failed,
}

class AgentVersionManifest {
  final String version;
  final String protocolVersion;
  final String packageUrl;
  final String checksum;
  final String? minimumCoordinatorVersion;
  final String? rollbackPackageUrl;

  const AgentVersionManifest({
    required this.version,
    required this.protocolVersion,
    required this.packageUrl,
    required this.checksum,
    this.minimumCoordinatorVersion,
    this.rollbackPackageUrl,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'protocolVersion': protocolVersion,
        'packageUrl': packageUrl,
        'checksum': checksum,
        'minimumCoordinatorVersion': minimumCoordinatorVersion,
        'rollbackPackageUrl': rollbackPackageUrl,
      };

  factory AgentVersionManifest.fromJson(Map<String, dynamic> json) {
    return AgentVersionManifest(
      version: json['version'] as String? ?? '',
      protocolVersion: json['protocolVersion'] as String? ?? '1',
      packageUrl: json['packageUrl'] as String? ?? '',
      checksum: json['checksum'] as String? ?? '',
      minimumCoordinatorVersion: json['minimumCoordinatorVersion'] as String?,
      rollbackPackageUrl: json['rollbackPackageUrl'] as String?,
    );
  }
}

class AgentUpgradePlan {
  final String id;
  final List<String> machineIds;
  final AgentVersionManifest targetVersion;
  final int batchSize;
  final int drainTimeoutSeconds;
  final bool rollbackOnHealthCheckFailure;
  final bool force;

  const AgentUpgradePlan({
    required this.id,
    required this.machineIds,
    required this.targetVersion,
    this.batchSize = 1,
    this.drainTimeoutSeconds = 300,
    this.rollbackOnHealthCheckFailure = true,
    this.force = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'machineIds': machineIds,
        'targetVersion': targetVersion.toJson(),
        'batchSize': batchSize,
        'drainTimeoutSeconds': drainTimeoutSeconds,
        'rollbackOnHealthCheckFailure': rollbackOnHealthCheckFailure,
        'force': force,
      };

  factory AgentUpgradePlan.fromJson(Map<String, dynamic> json) {
    return AgentUpgradePlan(
      id: json['id'] as String? ?? '',
      machineIds: (json['machineIds'] as List?)?.cast<String>() ?? const [],
      targetVersion: AgentVersionManifest.fromJson(
        json['targetVersion'] as Map<String, dynamic>? ?? const {},
      ),
      batchSize: (json['batchSize'] as num?)?.toInt() ?? 1,
      drainTimeoutSeconds:
          (json['drainTimeoutSeconds'] as num?)?.toInt() ?? 300,
      rollbackOnHealthCheckFailure:
          json['rollbackOnHealthCheckFailure'] as bool? ?? true,
      force: json['force'] as bool? ?? false,
    );
  }
}

class AgentUpgradeRolloutState {
  final String planId;
  final Map<String, AgentUpgradeMachineStatus> machineStatuses;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? message;

  const AgentUpgradeRolloutState({
    required this.planId,
    required this.machineStatuses,
    required this.startedAt,
    this.finishedAt,
    this.message,
  });

  bool get isFinished => finishedAt != null;

  AgentUpgradeRolloutState copyWith({
    String? planId,
    Map<String, AgentUpgradeMachineStatus>? machineStatuses,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? message,
  }) {
    return AgentUpgradeRolloutState(
      planId: planId ?? this.planId,
      machineStatuses: machineStatuses ?? this.machineStatuses,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'machineStatuses':
            machineStatuses.map((key, value) => MapEntry(key, value.name)),
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'message': message,
      };

  factory AgentUpgradeRolloutState.fromJson(Map<String, dynamic> json) {
    final rawStatuses =
        json['machineStatuses'] as Map<String, dynamic>? ?? const {};
    return AgentUpgradeRolloutState(
      planId: json['planId'] as String? ?? '',
      machineStatuses: rawStatuses.map(
        (key, value) => MapEntry(
          key,
          AgentUpgradeMachineStatus.values.firstWhere(
            (status) => status.name == value,
            orElse: () => AgentUpgradeMachineStatus.pending,
          ),
        ),
      ),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
      finishedAt: json['finishedAt'] != null
          ? DateTime.tryParse(json['finishedAt'] as String)
          : null,
      message: json['message'] as String?,
    );
  }
}
