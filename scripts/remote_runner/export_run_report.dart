import 'dart:io';

import 'package:apilens/features/remote_runner/application/run_report_service.dart';
import 'package:apilens/features/remote_runner/domain/models/load_profile.dart';
import 'package:apilens/features/remote_runner/domain/models/metric_window_event.dart';
import 'package:apilens/features/remote_runner/domain/models/metrics_models.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_run.dart';
import 'package:apilens/features/remote_runner/domain/models/run_report.dart';
import 'package:apilens/features/remote_runner/domain/models/run_shard.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow.dart';

void main(List<String> args) {
  final format = args.isNotEmpty ? args.first : 'markdown';
  final service = RunReportService();
  final report = service.buildReport(RunReportInput(
    plan: _samplePlan(),
    metrics: _sampleMetrics(),
  ));

  switch (format) {
    case 'json':
      stdout.write(service.exportJson(report));
    case 'csv':
      stdout.write(service.exportCsv(report));
    case 'markdown':
    default:
      stdout.write(service.exportMarkdown(report));
  }
}

RemoteRunPlan _samplePlan() {
  final draft = RemoteRunDraft(
    id: 'sample-run',
    workflowSnapshot: Workflow(
      id: 'sample-workflow',
      name: 'Sample Load Workflow',
      nodes: const [],
      edges: const [],
    ),
    loadProfile: const LoadProfile(
      virtualUsers: 100,
      durationSeconds: 60,
    ),
    createdAt: DateTime.now(),
  );

  return RemoteRunPlan(
    id: 'sample-run-plan',
    draft: draft,
    status: RemoteRunStatus.completed,
    plannedAt: DateTime.now(),
    shards: const [
      RunShard(
        id: 'sample-run-shard-001',
        runId: 'sample-run',
        agentId: 'agent-1',
        virtualUserRange: VirtualUserRange(
          startInclusive: 1,
          endInclusive: 100,
        ),
        rampUpOffsetMs: 0,
        durationSeconds: 60,
        concurrencyLimit: 50,
        status: RunShardStatus.completed,
      ),
    ],
  );
}

RunMetricsSnapshot _sampleMetrics() {
  return RunMetricsSnapshot(
    runId: 'sample-run',
    requestCount: 1000,
    errorCount: 7,
    updatedAt: DateTime.now(),
    nodes: const {
      'api1': NodeMetricsSnapshot(
        nodeId: 'api1',
        requestCount: 1000,
        errorCount: 7,
        statusCounts: {'200': 993, '500': 7},
        errorTypeCounts: {'http_500': 7},
        latency: LatencyHistogram(
          buckets: {100: 600, 250: 300, 500: 100},
          minMs: 12,
          maxMs: 500,
          sumMs: 170000,
          count: 1000,
        ),
      ),
    },
  );
}
