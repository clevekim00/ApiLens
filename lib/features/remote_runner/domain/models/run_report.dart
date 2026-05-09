import 'metrics_models.dart';
import 'remote_run.dart';
import 'run_shard.dart';

class NodeReport {
  final String nodeId;
  final int requestCount;
  final int errorCount;
  final double errorRate;
  final int p50Ms;
  final int p90Ms;
  final int p95Ms;
  final int p99Ms;
  final Map<String, int> statusCounts;
  final Map<String, int> errorTypeCounts;

  const NodeReport({
    required this.nodeId,
    required this.requestCount,
    required this.errorCount,
    required this.errorRate,
    required this.p50Ms,
    required this.p90Ms,
    required this.p95Ms,
    required this.p99Ms,
    this.statusCounts = const {},
    this.errorTypeCounts = const {},
  });

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'requestCount': requestCount,
        'errorCount': errorCount,
        'errorRate': errorRate,
        'p50Ms': p50Ms,
        'p90Ms': p90Ms,
        'p95Ms': p95Ms,
        'p99Ms': p99Ms,
        'statusCounts': statusCounts,
        'errorTypeCounts': errorTypeCounts,
      };
}

class AgentReport {
  final String agentId;
  final int shardCount;
  final int assignedVirtualUsers;
  final int completedShards;
  final int failedShards;
  final int lostShards;

  const AgentReport({
    required this.agentId,
    required this.shardCount,
    required this.assignedVirtualUsers,
    required this.completedShards,
    required this.failedShards,
    required this.lostShards,
  });

  Map<String, dynamic> toJson() => {
        'agentId': agentId,
        'shardCount': shardCount,
        'assignedVirtualUsers': assignedVirtualUsers,
        'completedShards': completedShards,
        'failedShards': failedShards,
        'lostShards': lostShards,
      };
}

class RunReport {
  final String runId;
  final String workflowName;
  final RemoteRunStatus status;
  final int configuredVirtualUsers;
  final int achievedRequestCount;
  final int errorCount;
  final double errorRate;
  final DateTime generatedAt;
  final List<NodeReport> nodes;
  final List<AgentReport> agents;
  final bool isPartial;
  final String? partialReason;

  const RunReport({
    required this.runId,
    required this.workflowName,
    required this.status,
    required this.configuredVirtualUsers,
    required this.achievedRequestCount,
    required this.errorCount,
    required this.errorRate,
    required this.generatedAt,
    this.nodes = const [],
    this.agents = const [],
    this.isPartial = false,
    this.partialReason,
  });

  Map<String, dynamic> toJson() => {
        'runId': runId,
        'workflowName': workflowName,
        'status': status.name,
        'configuredVirtualUsers': configuredVirtualUsers,
        'achievedRequestCount': achievedRequestCount,
        'errorCount': errorCount,
        'errorRate': errorRate,
        'generatedAt': generatedAt.toIso8601String(),
        'nodes': nodes.map((node) => node.toJson()).toList(),
        'agents': agents.map((agent) => agent.toJson()).toList(),
        'isPartial': isPartial,
        'partialReason': partialReason,
      };
}

class RunReportInput {
  final RemoteRunPlan plan;
  final RunMetricsSnapshot metrics;
  final bool isPartial;
  final String? partialReason;

  const RunReportInput({
    required this.plan,
    required this.metrics,
    this.isPartial = false,
    this.partialReason,
  });
}

extension RunShardReportFilters on Iterable<RunShard> {
  int countByStatus(RunShardStatus status) {
    return where((shard) => shard.status == status).length;
  }
}
