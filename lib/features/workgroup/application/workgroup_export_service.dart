import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/workgroup_model.dart';
import '../data/workgroup_repository.dart';
import '../../request/data/request_repository.dart';
import '../../request/models/request_model.dart';
import '../../workflow_editor/data/workflow_repository.dart';
import '../../workflow_editor/domain/models/workflow_model.dart';

final workgroupExportServiceProvider = Provider((ref) => WorkgroupExportService(ref));

class WorkgroupExportService {
  final Ref _ref;

  WorkgroupExportService(this._ref);

  WorkgroupRepository get _workgroupRepo => _ref.read(workgroupRepositoryProvider);
  RequestRepository get _requestRepo => _ref.read(requestRepositoryProvider);
  WorkflowRepository get _workflowRepo => _ref.read(workflowRepositoryProvider);

  /// Export Workgroup and its contents to a JSON String
  Future<String> exportWorkgroup(String groupId) async {
    final group = await _workgroupRepo.getWorkgroup(groupId);
    if (group == null) throw Exception('Workgroup not found');

    // Get Requests
    final allRequests = _requestRepo.getAll();
    final groupRequests = allRequests.where((r) => r.groupId == groupId).toList();

    // Get Workflows
    final allWorkflows = await _workflowRepo.getAll();
    final groupWorkflows = allWorkflows.where((w) => w.groupId == groupId).toList();

    final data = {
      'schemaVersion': 1,
      'kind': 'apilens.workgroup.export',
      'exportedAt': DateTime.now().toIso8601String(),
      'app': {
        'name': 'ApiLens',
        'version': '0.8.0', // TODO: Get from package_info
      },
      'workgroup': group.toJson(),
      'env': {
        // TODO: Integrate actual Environment export if they are scoped to workgroup
        'baseUrl': '{{env.baseUrl}}', 
      },
      'requests': groupRequests.map((r) => r.toJson()).toList(),
      'workflows': groupWorkflows.map((w) => w.toJson()).toList(),
      'importPolicyHints': {
        'idCollision': 'regenerate',
        'nameCollision': 'suffixImported',
      }
    };
    
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Import Workgroup from JSON String
  Future<void> importWorkgroup(String jsonString) async {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonString);
    } catch (e) {
      throw Exception('Invalid JSON format');
    }

    final kind = json['kind'];
    if (kind != 'apilens.workgroup.export') {
       // Allow legacy or permissive fallback? 
       // For now strict check as per new spec
       // But wait, existing exports might lack 'kind'. 
       // If meta type exists, check that.
       final meta = json['meta'] as Map?;
       if (kind == null && meta?['type'] == 'apilens_workgroup') {
         // Legacy V0 support
       } else if (kind != 'apilens.workgroup.export') {
         throw Exception('Invalid file type: $kind');
       }
    }

    final groupJson = json['workgroup'] as Map<String, dynamic>;
    final requestsJson = (json['requests'] as List?) ?? [];
    final workflowsJson = (json['workflows'] as List?) ?? [];

    // ID Regeneration
    final oldGroupId = groupJson['id'];
    final newGroupId = const Uuid().v4();
    
    // Name Collision Handling
    var name = groupJson['name'];
    final existingGroups = _workgroupRepo.getAll();
    if (existingGroups.any((g) => g.name == name)) {
      name = '$name (Imported)';
      // Simple suffix logic as per spec
    }

    final newGroup = WorkgroupModel.fromJson(groupJson).copyWith(
      id: newGroupId,
      name: name,
      parentId: 'no-workgroup', // Default import location
      isSystem: false,
    );
    
    await _workgroupRepo.save(newGroup);

    // Import Requests
    for (var r in requestsJson) {
      if (r is Map<String, dynamic>) {
        final newReq = RequestModel.fromJson(r).copyWith(
          id: const Uuid().v4(),
          groupId: newGroupId, // Relink to new group
        );
        await _requestRepo.save(newReq);
      }
    }

    // Import Workflows
    for (var w in workflowsJson) {
      if (w is Map<String, dynamic>) {
         final newWorkflow = WorkflowModel.fromJson(w).copyWith(
           id: const Uuid().v4(),
           groupId: newGroupId, // Relink to new group
         );
         await _workflowRepo.save(newWorkflow);
      }
    }
  }
}
