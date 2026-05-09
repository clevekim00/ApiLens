import '../domain/models/run_report.dart';

abstract class RemoteRunReportRepository {
  Future<void> saveReport(RunReport report);
  Future<RunReport?> getReport(String runId);
  Future<List<RunReport>> getAllReports();
}

class InMemoryRemoteRunReportRepository implements RemoteRunReportRepository {
  final Map<String, RunReport> _reports = {};

  @override
  Future<void> saveReport(RunReport report) async {
    _reports[report.runId] = report;
  }

  @override
  Future<RunReport?> getReport(String runId) async {
    return _reports[runId];
  }

  @override
  Future<List<RunReport>> getAllReports() async {
    return _reports.values.toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
  }
}
