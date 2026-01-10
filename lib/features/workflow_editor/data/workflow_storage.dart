import 'dart:convert';
import 'package:hive/hive.dart';
import '../domain/models/workflow.dart';

class WorkflowStorage {
  static const String _boxName = 'workflows_box';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<void> saveWorkflow(Workflow workflow) async {
    final box = await _getBox();
    final jsonMap = workflow.toJson();
    // We store as Map directly, Hive handles basic types (String, num, Map, List)
    // Or we could store as JSON string if we want ensuring total independence.
    // Let's store as JSON string to be safe and consistent with 'export'.
    await box.put(workflow.id, jsonEncode(jsonMap));
  }

  Future<List<Workflow>> loadAllWorkflows() async {
    final box = await _getBox();
    final List<Workflow> list = [];
    
    for (var i = 0; i < box.length; i++) {
      final key = box.keyAt(i);
      final value = box.get(key);
      if (value is String) {
        try {
          final jsonMap = jsonDecode(value);
          list.add(Workflow.fromJson(jsonMap));
        } catch (e) {
          print('Error loading workflow $key: $e');
        }
      }
    }
    // Sort by last modified desc
    list.sort((a, b) => (b.lastModified ?? DateTime(0)).compareTo(a.lastModified ?? DateTime(0)));
    return list;
  }

  Future<void> deleteWorkflow(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
  
  Future<Workflow?> loadWorkflow(String id) async {
    final box = await _getBox();
    final value = box.get(id);
    if (value is String) {
       return Workflow.fromJson(jsonDecode(value));
    }
    return null;
  }
}
