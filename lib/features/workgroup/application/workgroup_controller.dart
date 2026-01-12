import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../domain/models/workgroup_model.dart';
import '../data/workgroup_repository.dart';
import '../../request/application/saved_request_controller.dart';
import '../../request/models/request_model.dart';

class WorkgroupController extends StateNotifier<List<WorkgroupModel>> {
  final WorkgroupRepository _repository;
  final Ref _ref;

  WorkgroupController(this._repository, this._ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final groups = _repository.getAll();
    state = groups;
    if (groups.isEmpty) {
      // Seed Data could be added here or via a dedicated bootstrapper
      // But adding it here ensures it appears on first run
      await _initSampleData();
    }
  }

  Future<void> _initSampleData() async {
    // Double check just in case
    if (_repository.getAll().isNotEmpty) return;
    
    final sampleGroup = WorkgroupModel.create(
      name: 'My First Project',
      type: WorkgroupType.requestCollection,
      description: 'Welcome to ApiLens! This is a sample workgroup.'
    );
    await _repository.save(sampleGroup);
    state = _repository.getAll();
  }

  Future<void> createGroup(String name, WorkgroupType type, {String? parentId, String? description}) async {
    final group = WorkgroupModel.create(
      name: name, 
      type: type, 
      parentId: parentId,
      description: description ?? ''
    );
    await _repository.save(group);
    _load();
  }

  Future<void> updateGroup(String id, {String? name, String? parentId, String? description}) async {
    final current = state.firstWhere((g) => g.id == id);
    if (current.isSystem && name != null && name != current.name) {
      // Prevent renaming system group? Or allows it? 
      // Requirement said "rename 불가" or "rename 금지".
      // Let's prevent it.
      throw Exception('Cannot rename system group');
    }
    
    final updated = current.copyWith(
      name: name, 
      parentId: parentId,
      description: description
    );
    await _repository.save(updated);
    _load();
  }

  Future<void> deleteGroup(String id, {bool moveToSystem = true}) async {
    final current = state.firstWhere((g) => g.id == id, orElse: () => WorkgroupModel.systemRoot());
    if (current.isSystem) throw Exception('Cannot delete system group');

    // 1. Get all descendants
    final descendants = _getAllDescendants(id);
    final allIdsToDelete = [id, ...descendants.map((g) => g.id)];
    
    // 2. Handle Requests (Delete or Move)
    final requestController = _ref.read(savedRequestControllerProvider.notifier);
    final allRequests = _ref.read(savedRequestControllerProvider);
    
    for (final req in allRequests) {
      if (allIdsToDelete.contains(req.groupId)) {
        if (moveToSystem) {
           await requestController.moveRequest(req.id, 'no-workgroup');
        } else {
           await requestController.deleteRequest(req.id);
        }
      }
    }

    // 3. Delete groups (Folders always deleted, logic is about content)
    for (final groupId in allIdsToDelete) {
      await _repository.delete(groupId);
    }
    
    _load();
  }
  
  List<WorkgroupModel> _getAllDescendants(String parentId) {
    final children = state.where((g) => g.parentId == parentId).toList();
    final descendants = <WorkgroupModel>[...children];
    for (final child in children) {
      descendants.addAll(_getAllDescendants(child.id));
    }
    return descendants;
  }

  // --- Export / Import ---

  String exportWorkgroup(String groupId) {
    // 1. Get target group and all descendants
    final rootGroup = state.firstWhere((g) => g.id == groupId);
    final descendants = _getAllDescendants(groupId);
    final allGroups = [rootGroup, ...descendants];
    
    // 2. Get all requests in these groups
    final allRequests = _ref.read(savedRequestControllerProvider);
    final groupIds = allGroups.map((g) => g.id).toSet();
    final relatedRequests = allRequests.where((r) => r.groupId != null && groupIds.contains(r.groupId)).toList();
    
    // 3. Construct JSON Structure
    final exportData = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'rootGroupId': groupId,
      'groups': allGroups.map((g) => g.toJson()).toList(),
      'requests': relatedRequests.map((r) => r.toJson()).toList(),
    };
    
    final encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(exportData);
  }

  Future<void> importWorkgroup(String jsonString, {String? targetParentId}) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final version = data['version'] as int? ?? 1;
      if (version != 1) throw Exception('Unsupported version');

      final rawGroups = (data['groups'] as List).map((e) => WorkgroupModel.fromJson(e)).toList();
      final rawRequests = (data['requests'] as List).map((e) => RequestModel.fromJson(e)).toList();
      
      final oldRootId = data['rootGroupId'] as String;
      
      // ID Mapping to prevent collisions
      final idMap = <String, String>{}; // oldId -> newId
      
      // Generate new IDs for groups
      for (final g in rawGroups) {
        idMap[g.id] = const Uuid().v4();
      }
      
      // Re-create groups with new IDs and hierarchy
      for (final g in rawGroups) {
        String? newParentId;
        if (g.id == oldRootId) {
           // The root of the import becomes a child of targetParentId (or system root if null)
           newParentId = targetParentId ?? 'no-workgroup';
        } else {
           // Child nodes point to their new parent ID
           newParentId = idMap[g.parentId]; 
        }
        
        final newGroup = g.copyWith(
          // Reset system flag on import? Usually yes.
          isSystem: false, 
          // New ID
          // Parent ID
        ); 
        // We need to construct manually due to copyWith limit
        final toSave = WorkgroupModel(
            id: idMap[g.id]!, 
            name: g.name, 
            description: g.description,
            parentId: newParentId, 
            type: g.type,
            icon: g.icon,
            isSystem: false, // Imported groups are never system
            createdAt: DateTime.now(),
            updatedAt: DateTime.now()
        );

        await _repository.save(toSave);
      }
      
      // Re-create requests with new IDs and new group IDs
      final requestController = _ref.read(savedRequestControllerProvider.notifier);
      
      for (final r in rawRequests) {
        final newGroupId = idMap[r.groupId];
        if (newGroupId != null) { 
          final newRequest = r.copyWith(
            id: const Uuid().v4(),
            groupId: newGroupId, // Use mapped group ID
          );
          await requestController.saveRequest(newRequest);
        }
      }
      
      _load();
      
    } catch (e) {
      throw Exception('Import failed: $e');
    }
  }
}

final workgroupControllerProvider = StateNotifierProvider<WorkgroupController, List<WorkgroupModel>>((ref) {
  final repo = ref.watch(workgroupRepositoryProvider);
  return WorkgroupController(repo, ref);
});

// Selection State
final activeWorkgroupIdProvider = StateProvider<String?>((ref) => null);

// Helper provider to get children of a specific group
final folderChildrenProvider = Provider.family<List<WorkgroupModel>, String?>((ref, parentId) {
  final all = ref.watch(workgroupControllerProvider);
  return all.where((g) => g.parentId == parentId).toList();
});
