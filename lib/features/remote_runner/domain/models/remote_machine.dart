enum RemoteMachineAdminState {
  enabled,
  disabled,
  draining,
}

class RemoteMachine {
  final String id;
  final String name;
  final String host;
  final String platform;
  final List<String> labels;
  final String? credentialRef;
  final String? agentInstallPath;
  final RemoteMachineAdminState adminState;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RemoteMachine({
    required this.id,
    required this.name,
    required this.host,
    this.platform = 'unknown',
    this.labels = const [],
    this.credentialRef,
    this.agentInstallPath,
    this.adminState = RemoteMachineAdminState.enabled,
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSchedulable => adminState == RemoteMachineAdminState.enabled;

  RemoteMachine copyWith({
    String? id,
    String? name,
    String? host,
    String? platform,
    List<String>? labels,
    String? credentialRef,
    String? agentInstallPath,
    RemoteMachineAdminState? adminState,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RemoteMachine(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      platform: platform ?? this.platform,
      labels: labels ?? this.labels,
      credentialRef: credentialRef ?? this.credentialRef,
      agentInstallPath: agentInstallPath ?? this.agentInstallPath,
      adminState: adminState ?? this.adminState,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'platform': platform,
        'labels': labels,
        'credentialRef': credentialRef,
        'agentInstallPath': agentInstallPath,
        'adminState': adminState.name,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RemoteMachine.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return RemoteMachine(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Machine',
      host: json['host'] as String? ?? '',
      platform: json['platform'] as String? ?? 'unknown',
      labels: (json['labels'] as List?)?.cast<String>() ?? const [],
      credentialRef: json['credentialRef'] as String?,
      agentInstallPath: json['agentInstallPath'] as String?,
      adminState: RemoteMachineAdminState.values.firstWhere(
        (state) => state.name == json['adminState'],
        orElse: () => RemoteMachineAdminState.enabled,
      ),
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : now,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : now,
    );
  }
}
