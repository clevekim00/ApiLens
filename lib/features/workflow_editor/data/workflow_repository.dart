import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/workflow_model.dart';

class WorkflowRepository {
  static const String _boxName = 'workflows';
  late Box<WorkflowModel> _box;

  Future<void> init() async {
    // Note: Adapters should be registered in main.dart or a centralized init function
    _box = await Hive.openBox<WorkflowModel>(_boxName);
  }

  List<WorkflowModel> getAll() {
    return _box.values.toList();
  }

  List<WorkflowModel> getByGroup(String groupId) {
    return _box.values.where((w) => w.groupId == groupId).toList();
  }

  WorkflowModel? get(String id) {
    return _box.get(id);
  }

  Future<void> save(WorkflowModel workflow) async {
    await _box.put(workflow.id, workflow);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
  
  Future<void> clear() async {
    await _box.clear();
  }

  String exportJson(WorkflowModel workflow) {
    return jsonEncode(workflow.toJson());
  }

  WorkflowModel importJson(String jsonStr) {
    final json = jsonDecode(jsonStr);
    return WorkflowModel.fromJson(json);
  }
}

final workflowRepositoryProvider = Provider<WorkflowRepository>((ref) {
  return WorkflowRepository();
});
