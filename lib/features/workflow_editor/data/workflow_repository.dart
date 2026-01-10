import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/workflow.dart';
import 'workflow_storage.dart';

class WorkflowRepository {
  final WorkflowStorage _storage;

  WorkflowRepository(this._storage);

  Future<void> save(Workflow workflow) async {
    await _storage.saveWorkflow(workflow);
  }

  Future<List<Workflow>> getAll() async {
    return await _storage.loadAllWorkflows();
  }

  Future<void> delete(String id) async {
    await _storage.deleteWorkflow(id);
  }
  
  // Export to JSON String
  String exportJson(Workflow workflow) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(workflow.toJson());
  }

  // Import from JSON String
  Workflow importJson(String jsonString) {
    try {
      final jsonMap = jsonDecode(jsonString);
      return Workflow.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Invalid Workflow JSON: $e');
    }
  }
}

final workflowRepositoryProvider = Provider<WorkflowRepository>((ref) {
  return WorkflowRepository(WorkflowStorage());
});
