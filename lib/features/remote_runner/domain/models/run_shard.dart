enum RunShardStatus {
  queued,
  dispatching,
  running,
  completed,
  failed,
  cancelled,
  lost,
}

class VirtualUserRange {
  final int startInclusive;
  final int endInclusive;

  const VirtualUserRange({
    required this.startInclusive,
    required this.endInclusive,
  });

  int get count {
    if (endInclusive < startInclusive) return 0;
    return endInclusive - startInclusive + 1;
  }

  Map<String, dynamic> toJson() => {
        'startInclusive': startInclusive,
        'endInclusive': endInclusive,
      };

  factory VirtualUserRange.fromJson(Map<String, dynamic> json) {
    return VirtualUserRange(
      startInclusive: (json['startInclusive'] as num?)?.toInt() ?? 0,
      endInclusive: (json['endInclusive'] as num?)?.toInt() ?? -1,
    );
  }
}

class RunShard {
  final String id;
  final String runId;
  final String agentId;
  final VirtualUserRange virtualUserRange;
  final int rampUpOffsetMs;
  final int durationSeconds;
  final int concurrencyLimit;
  final RunShardStatus status;

  const RunShard({
    required this.id,
    required this.runId,
    required this.agentId,
    required this.virtualUserRange,
    required this.rampUpOffsetMs,
    required this.durationSeconds,
    required this.concurrencyLimit,
    this.status = RunShardStatus.queued,
  });

  RunShard copyWith({
    String? id,
    String? runId,
    String? agentId,
    VirtualUserRange? virtualUserRange,
    int? rampUpOffsetMs,
    int? durationSeconds,
    int? concurrencyLimit,
    RunShardStatus? status,
  }) {
    return RunShard(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      agentId: agentId ?? this.agentId,
      virtualUserRange: virtualUserRange ?? this.virtualUserRange,
      rampUpOffsetMs: rampUpOffsetMs ?? this.rampUpOffsetMs,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      concurrencyLimit: concurrencyLimit ?? this.concurrencyLimit,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'runId': runId,
        'agentId': agentId,
        'virtualUserRange': virtualUserRange.toJson(),
        'rampUpOffsetMs': rampUpOffsetMs,
        'durationSeconds': durationSeconds,
        'concurrencyLimit': concurrencyLimit,
        'status': status.name,
      };

  factory RunShard.fromJson(Map<String, dynamic> json) {
    return RunShard(
      id: json['id'] as String? ?? '',
      runId: json['runId'] as String? ?? '',
      agentId: json['agentId'] as String? ?? '',
      virtualUserRange: VirtualUserRange.fromJson(
        json['virtualUserRange'] as Map<String, dynamic>? ?? const {},
      ),
      rampUpOffsetMs: (json['rampUpOffsetMs'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      concurrencyLimit: (json['concurrencyLimit'] as num?)?.toInt() ?? 0,
      status: RunShardStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RunShardStatus.queued,
      ),
    );
  }
}
