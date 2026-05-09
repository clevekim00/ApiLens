class LatencyHistogram {
  final Map<int, int> buckets;
  final int minMs;
  final int maxMs;
  final int sumMs;
  final int count;

  const LatencyHistogram({
    this.buckets = const {},
    this.minMs = 0,
    this.maxMs = 0,
    this.sumMs = 0,
    this.count = 0,
  });

  Map<String, dynamic> toJson() => {
        'buckets': buckets.map((key, value) => MapEntry(key.toString(), value)),
        'minMs': minMs,
        'maxMs': maxMs,
        'sumMs': sumMs,
        'count': count,
      };

  factory LatencyHistogram.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LatencyHistogram();
    final rawBuckets = json['buckets'] as Map<String, dynamic>? ?? const {};
    return LatencyHistogram(
      buckets: rawBuckets.map(
        (key, value) => MapEntry(int.parse(key), (value as num).toInt()),
      ),
      minMs: (json['minMs'] as num?)?.toInt() ?? 0,
      maxMs: (json['maxMs'] as num?)?.toInt() ?? 0,
      sumMs: (json['sumMs'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class MetricWindowEvent {
  final String id;
  final String runId;
  final String shardId;
  final String agentId;
  final String nodeId;
  final DateTime windowStartedAt;
  final int windowMs;
  final int sequence;
  final int requestCount;
  final int errorCount;
  final Map<String, int> statusCounts;
  final Map<String, int> errorTypeCounts;
  final LatencyHistogram latency;

  const MetricWindowEvent({
    required this.id,
    required this.runId,
    required this.shardId,
    required this.agentId,
    required this.nodeId,
    required this.windowStartedAt,
    required this.windowMs,
    required this.sequence,
    required this.requestCount,
    required this.errorCount,
    this.statusCounts = const {},
    this.errorTypeCounts = const {},
    this.latency = const LatencyHistogram(),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'runId': runId,
        'shardId': shardId,
        'agentId': agentId,
        'nodeId': nodeId,
        'windowStartedAt': windowStartedAt.toIso8601String(),
        'windowMs': windowMs,
        'sequence': sequence,
        'requestCount': requestCount,
        'errorCount': errorCount,
        'statusCounts': statusCounts,
        'errorTypeCounts': errorTypeCounts,
        'latency': latency.toJson(),
      };

  factory MetricWindowEvent.fromJson(Map<String, dynamic> json) {
    return MetricWindowEvent(
      id: json['id'] as String? ?? '',
      runId: json['runId'] as String? ?? '',
      shardId: json['shardId'] as String? ?? '',
      agentId: json['agentId'] as String? ?? '',
      nodeId: json['nodeId'] as String? ?? '',
      windowStartedAt: json['windowStartedAt'] != null
          ? DateTime.parse(json['windowStartedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
      windowMs: (json['windowMs'] as num?)?.toInt() ?? 1000,
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      requestCount: (json['requestCount'] as num?)?.toInt() ?? 0,
      errorCount: (json['errorCount'] as num?)?.toInt() ?? 0,
      statusCounts: (json['statusCounts'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          ) ??
          const {},
      errorTypeCounts: (json['errorTypeCounts'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          ) ??
          const {},
      latency: LatencyHistogram.fromJson(
        json['latency'] as Map<String, dynamic>?,
      ),
    );
  }
}
