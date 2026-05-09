import 'package:apilens/features/remote_runner/application/run_report_service.dart';
import 'package:apilens/features/remote_runner/data/remote_run_repository.dart';
import 'package:apilens/features/remote_runner/domain/models/load_profile.dart';
import 'package:apilens/features/remote_runner/domain/models/metric_window_event.dart';
import 'package:apilens/features/remote_runner/domain/models/metrics_models.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_run.dart';
import 'package:apilens/features/remote_runner/domain/models/run_report.dart';
import 'package:apilens/features/remote_runner/domain/models/run_shard.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunReportService', () {
    test('builds report with node percentiles and agent summary', () {
      final service = RunReportService(
        now: () => DateTime.utc(2026, 5, 9, 12),
      );

      final report = service.buildReport(RunReportInput(
        plan: _plan(),
        metrics: _metrics(),
      ));

      expect(report.runId, 'run-1');
      expect(report.workflowName, 'Load workflow');
      expect(report.configuredVirtualUsers, 100);
      expect(report.achievedRequestCount, 20);
      expect(report.errorCount, 2);
      expect(report.nodes.single.p50Ms, 100);
      expect(report.nodes.single.p95Ms, 500);
      expect(report.agents.single.assignedVirtualUsers, 100);
      expect(report.agents.single.completedShards, 1);
    });

    test('exports JSON CSV and Markdown', () {
      final service = RunReportService(
        now: () => DateTime.utc(2026, 5, 9, 12),
      );
      final report = service.buildReport(RunReportInput(
        plan: _plan(),
        metrics: _metrics(),
        isPartial: true,
        partialReason: 'flush retry queue pending',
      ));

      final json = service.exportJson(report);
      final csv = service.exportCsv(report);
      final markdown = service.exportMarkdown(report);

      expect(json, contains('"runId": "run-1"'));
      expect(csv, contains('section,id,metric,value'));
      expect(csv, contains('node,api1,p95Ms,500'));
      expect(markdown, contains('# Load Hub Run Report'));
      expect(markdown, contains('Partial report'));
    });

    test('saves report through repository when configured', () async {
      final repository = InMemoryRemoteRunReportRepository();
      final service = RunReportService(
        repository: repository,
        now: () => DateTime.utc(2026, 5, 9, 12),
      );

      final report = await service.buildAndSaveReport(RunReportInput(
        plan: _plan(),
        metrics: _metrics(),
      ));

      expect(await repository.getReport(report.runId), isNotNull);
      expect(await repository.getAllReports(), hasLength(1));
    });
  });
}

RemoteRunPlan _plan() {
  final draft = RemoteRunDraft(
    id: 'run-1',
    workflowSnapshot: Workflow(
      id: 'workflow-1',
      name: 'Load workflow',
      nodes: const [],
      edges: const [],
    ),
    loadProfile: const LoadProfile(
      virtualUsers: 100,
      durationSeconds: 60,
    ),
    createdAt: DateTime.utc(2026, 5, 9),
  );

  return RemoteRunPlan(
    id: 'run-1-plan',
    draft: draft,
    status: RemoteRunStatus.completed,
    plannedAt: DateTime.utc(2026, 5, 9),
    shards: const [
      RunShard(
        id: 'run-1-shard-001',
        runId: 'run-1',
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

RunMetricsSnapshot _metrics() {
  return RunMetricsSnapshot(
    runId: 'run-1',
    requestCount: 20,
    errorCount: 2,
    updatedAt: DateTime.utc(2026, 5, 9, 12),
    nodes: const {
      'api1': NodeMetricsSnapshot(
        nodeId: 'api1',
        requestCount: 20,
        errorCount: 2,
        statusCounts: {'200': 18, '500': 2},
        errorTypeCounts: {'http_500': 2},
        latency: LatencyHistogram(
          buckets: {100: 10, 250: 8, 500: 2},
          minMs: 20,
          maxMs: 500,
          sumMs: 4200,
          count: 20,
        ),
      ),
    },
  );
}
