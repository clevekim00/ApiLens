class MachineResourceSnapshot {
  final double cpuUsagePercent;
  final double memoryUsagePercent;
  final int memoryUsedBytes;
  final int memoryTotalBytes;
  final double diskReadBytesPerSecond;
  final double diskWriteBytesPerSecond;
  final double networkRxBytesPerSecond;
  final double networkTxBytesPerSecond;
  final double? loadAverage1m;
  final DateTime capturedAt;

  const MachineResourceSnapshot({
    required this.cpuUsagePercent,
    required this.memoryUsagePercent,
    required this.memoryUsedBytes,
    required this.memoryTotalBytes,
    required this.diskReadBytesPerSecond,
    required this.diskWriteBytesPerSecond,
    required this.networkRxBytesPerSecond,
    required this.networkTxBytesPerSecond,
    this.loadAverage1m,
    required this.capturedAt,
  });

  bool get isUnderPressure {
    return cpuUsagePercent >= 85 || memoryUsagePercent >= 90;
  }

  Map<String, dynamic> toJson() => {
        'cpuUsagePercent': cpuUsagePercent,
        'memoryUsagePercent': memoryUsagePercent,
        'memoryUsedBytes': memoryUsedBytes,
        'memoryTotalBytes': memoryTotalBytes,
        'diskReadBytesPerSecond': diskReadBytesPerSecond,
        'diskWriteBytesPerSecond': diskWriteBytesPerSecond,
        'networkRxBytesPerSecond': networkRxBytesPerSecond,
        'networkTxBytesPerSecond': networkTxBytesPerSecond,
        'loadAverage1m': loadAverage1m,
        'capturedAt': capturedAt.toIso8601String(),
      };

  factory MachineResourceSnapshot.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MachineResourceSnapshot.empty(
          DateTime.fromMillisecondsSinceEpoch(0));
    }

    return MachineResourceSnapshot(
      cpuUsagePercent: (json['cpuUsagePercent'] as num?)?.toDouble() ?? 0,
      memoryUsagePercent: (json['memoryUsagePercent'] as num?)?.toDouble() ?? 0,
      memoryUsedBytes: (json['memoryUsedBytes'] as num?)?.toInt() ?? 0,
      memoryTotalBytes: (json['memoryTotalBytes'] as num?)?.toInt() ?? 0,
      diskReadBytesPerSecond:
          (json['diskReadBytesPerSecond'] as num?)?.toDouble() ?? 0,
      diskWriteBytesPerSecond:
          (json['diskWriteBytesPerSecond'] as num?)?.toDouble() ?? 0,
      networkRxBytesPerSecond:
          (json['networkRxBytesPerSecond'] as num?)?.toDouble() ?? 0,
      networkTxBytesPerSecond:
          (json['networkTxBytesPerSecond'] as num?)?.toDouble() ?? 0,
      loadAverage1m: (json['loadAverage1m'] as num?)?.toDouble(),
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory MachineResourceSnapshot.empty(DateTime capturedAt) {
    return MachineResourceSnapshot(
      cpuUsagePercent: 0,
      memoryUsagePercent: 0,
      memoryUsedBytes: 0,
      memoryTotalBytes: 0,
      diskReadBytesPerSecond: 0,
      diskWriteBytesPerSecond: 0,
      networkRxBytesPerSecond: 0,
      networkTxBytesPerSecond: 0,
      capturedAt: capturedAt,
    );
  }
}
