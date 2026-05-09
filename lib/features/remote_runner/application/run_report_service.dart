import 'dart:convert';

import '../data/remote_run_repository.dart';
import '../domain/models/metric_window_event.dart';
import '../domain/models/metrics_models.dart';
import '../domain/models/remote_run.dart';
import '../domain/models/run_report.dart';
import '../domain/models/run_shard.dart';

class RunReportService {
  final RemoteRunReportRepository? _repository;
  final DateTime Function() _now;

  RunReportService({
    RemoteRunReportRepository? repository,
    DateTime Function()? now,
  })  : _repository = repository,
        _now = now ?? DateTime.now;

  RunReport buildReport(RunReportInput input) {
    final plan = input.plan;
    final metrics = input.metrics;

    return RunReport(
      runId: plan.draft.id,
      workflowName: plan.draft.workflowSnapshot.name,
      status: plan.status,
      configuredVirtualUsers: plan.draft.loadProfile.virtualUsers,
      achievedRequestCount: metrics.requestCount,
      errorCount: metrics.errorCount,
      errorRate: metrics.errorRate,
      generatedAt: _now(),
      nodes: _buildNodeReports(metrics),
      agents: _buildAgentReports(plan),
      isPartial: input.isPartial,
      partialReason: input.partialReason,
    );
  }

  Future<RunReport> buildAndSaveReport(RunReportInput input) async {
    final report = buildReport(input);
    await _repository?.saveReport(report);
    return report;
  }

  String exportJson(RunReport report) {
    return const JsonEncoder.withIndent('  ').convert(report.toJson());
  }

  String exportCsv(RunReport report) {
    final buffer = StringBuffer()
      ..writeln('section,id,metric,value')
      ..writeln(
          'run,${_csv(report.runId)},workflow,${_csv(report.workflowName)}')
      ..writeln('run,${_csv(report.runId)},status,${report.status.name}')
      ..writeln(
        'run,${_csv(report.runId)},configuredVirtualUsers,'
        '${report.configuredVirtualUsers}',
      )
      ..writeln(
        'run,${_csv(report.runId)},achievedRequestCount,'
        '${report.achievedRequestCount}',
      )
      ..writeln('run,${_csv(report.runId)},errorCount,${report.errorCount}')
      ..writeln('run,${_csv(report.runId)},errorRate,${report.errorRate}');

    for (final node in report.nodes) {
      buffer
        ..writeln('node,${_csv(node.nodeId)},requestCount,${node.requestCount}')
        ..writeln('node,${_csv(node.nodeId)},errorCount,${node.errorCount}')
        ..writeln('node,${_csv(node.nodeId)},p50Ms,${node.p50Ms}')
        ..writeln('node,${_csv(node.nodeId)},p90Ms,${node.p90Ms}')
        ..writeln('node,${_csv(node.nodeId)},p95Ms,${node.p95Ms}')
        ..writeln('node,${_csv(node.nodeId)},p99Ms,${node.p99Ms}');
    }

    for (final agent in report.agents) {
      buffer
        ..writeln(
          'agent,${_csv(agent.agentId)},assignedVirtualUsers,'
          '${agent.assignedVirtualUsers}',
        )
        ..writeln(
          'agent,${_csv(agent.agentId)},completedShards,'
          '${agent.completedShards}',
        )
        ..writeln(
          'agent,${_csv(agent.agentId)},failedShards,${agent.failedShards}',
        )
        ..writeln(
            'agent,${_csv(agent.agentId)},lostShards,${agent.lostShards}');
    }

    return buffer.toString();
  }

  String exportMarkdown(RunReport report) {
    final buffer = StringBuffer()
      ..writeln('# Load Hub Run Report')
      ..writeln()
      ..writeln('- Run ID: `${report.runId}`')
      ..writeln('- Workflow: ${report.workflowName}')
      ..writeln('- Status: `${report.status.name}`')
      ..writeln('- Configured VU: ${report.configuredVirtualUsers}')
      ..writeln('- Achieved Requests: ${report.achievedRequestCount}')
      ..writeln('- Errors: ${report.errorCount}')
      ..writeln(
          '- Error Rate: ${(report.errorRate * 100).toStringAsFixed(2)}%');

    if (report.isPartial) {
      buffer
        ..writeln()
        ..writeln('> Partial report: ${report.partialReason ?? 'unknown'}');
    }

    buffer
      ..writeln()
      ..writeln('## Node Metrics')
      ..writeln()
      ..writeln('| Node | Requests | Errors | p50 | p90 | p95 | p99 |')
      ..writeln('|---|---:|---:|---:|---:|---:|---:|');
    for (final node in report.nodes) {
      buffer.writeln(
        '| ${node.nodeId} | ${node.requestCount} | ${node.errorCount} | '
        '${node.p50Ms} | ${node.p90Ms} | ${node.p95Ms} | ${node.p99Ms} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('## Agent Summary')
      ..writeln()
      ..writeln('| Agent | VU | Shards | Completed | Failed | Lost |')
      ..writeln('|---|---:|---:|---:|---:|---:|');
    for (final agent in report.agents) {
      buffer.writeln(
        '| ${agent.agentId} | ${agent.assignedVirtualUsers} | '
        '${agent.shardCount} | ${agent.completedShards} | '
        '${agent.failedShards} | ${agent.lostShards} |',
      );
    }

    return buffer.toString();
  }

  List<NodeReport> _buildNodeReports(RunMetricsSnapshot metrics) {
    final reports = metrics.nodes.values.map((node) {
      return NodeReport(
        nodeId: node.nodeId,
        requestCount: node.requestCount,
        errorCount: node.errorCount,
        errorRate: node.errorRate,
        p50Ms: _percentile(node.latency, 0.50),
        p90Ms: _percentile(node.latency, 0.90),
        p95Ms: _percentile(node.latency, 0.95),
        p99Ms: _percentile(node.latency, 0.99),
        statusCounts: node.statusCounts,
        errorTypeCounts: node.errorTypeCounts,
      );
    }).toList();
    reports.sort((a, b) => a.nodeId.compareTo(b.nodeId));
    return reports;
  }

  List<AgentReport> _buildAgentReports(RemoteRunPlan plan) {
    final shardsByAgent = <String, List<RunShard>>{};
    for (final shard in plan.shards) {
      shardsByAgent.putIfAbsent(shard.agentId, () => []).add(shard);
    }

    final reports = shardsByAgent.entries.map((entry) {
      final shards = entry.value;
      final assignedVirtualUsers = shards.fold<int>(
        0,
        (sum, shard) => sum + shard.virtualUserRange.count,
      );
      return AgentReport(
        agentId: entry.key,
        shardCount: shards.length,
        assignedVirtualUsers: assignedVirtualUsers,
        completedShards: shards.countByStatus(RunShardStatus.completed),
        failedShards: shards.countByStatus(RunShardStatus.failed),
        lostShards: shards.countByStatus(RunShardStatus.lost),
      );
    }).toList();
    reports.sort((a, b) => a.agentId.compareTo(b.agentId));
    return reports;
  }

  int _percentile(LatencyHistogram histogram, double percentile) {
    if (histogram.count <= 0 || histogram.buckets.isEmpty) return 0;
    final threshold = (histogram.count * percentile).ceil();
    final sortedBuckets = histogram.buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    var seen = 0;
    for (final bucket in sortedBuckets) {
      seen += bucket.value;
      if (seen >= threshold) return bucket.key;
    }
    return sortedBuckets.last.key;
  }

  String _csv(Object? value) {
    final raw = value?.toString() ?? '';
    if (!raw.contains(',') && !raw.contains('"') && !raw.contains('\n')) {
      return raw;
    }
    return '"${raw.replaceAll('"', '""')}"';
  }
}
