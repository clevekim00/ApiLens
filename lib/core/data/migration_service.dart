import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../features/request/models/request_model.dart';
import '../../features/workflow_editor/domain/models/node_config.dart';
import '../../features/workflow_editor/domain/models/workflow.dart';
import '../../features/workflow_editor/domain/models/workflow_node.dart';
import '../../features/workgroup/domain/models/workgroup_model.dart';

class MigrationService {
  static const int currentSchemaVersion = 3;

  static const String _metaBoxName = 'apilens_migrations';
  static const String _backupBoxName = 'apilens_migration_backups';
  static const String _legacyRequestBoxName = 'requests';
  static const String _requestBoxName = 'saved_requests';
  static const String _workgroupBoxName = 'workgroups';
  static const String _workflowBoxName = 'workflows_box';
  static const String _systemRootId = 'no-workgroup';

  Future<MigrationRunReport> run() async {
    final metaBox = await _openBox(_metaBoxName);
    final backupBox = await _openBox(_backupBoxName);
    final report = MigrationRunReport(startedAt: DateTime.now());

    final migrations = <_MigrationStep>[
      _MigrationStep(
        id: '001_ensure_system_workgroup',
        description: 'Ensure the system fallback workgroup exists.',
        execute: () => _ensureSystemWorkgroup(backupBox),
      ),
      _MigrationStep(
        id: '002_normalize_saved_requests',
        description: 'Move legacy requests and normalize request group links.',
        execute: () => _normalizeSavedRequests(backupBox),
      ),
      _MigrationStep(
        id: '003_normalize_workflows',
        description:
            'Normalize workflow group links, schema version, node ports, and execution policy defaults.',
        execute: () => _normalizeWorkflows(backupBox),
      ),
    ];

    for (final migration in migrations) {
      if (metaBox.containsKey(migration.id)) {
        report.skipped.add(migration.id);
        continue;
      }

      try {
        final result = await migration.execute();
        await metaBox.put(migration.id, {
          'id': migration.id,
          'description': migration.description,
          'appliedAt': DateTime.now().toIso8601String(),
          'changedEntries': result.changedEntries,
          'details': result.details,
        });
        report.applied.add(result);
      } catch (error, stackTrace) {
        debugPrint('Migration failed: ${migration.id}: $error');
        debugPrintStack(stackTrace: stackTrace);
        report.failed.add(MigrationFailure(migration.id, error.toString()));
        rethrow;
      }
    }

    await metaBox.put('schemaVersion', currentSchemaVersion);
    report.finishedAt = DateTime.now();

    if (report.applied.isNotEmpty || report.failed.isNotEmpty) {
      debugPrint(report.summary);
    }

    return report;
  }

  Future<MigrationStepResult> _ensureSystemWorkgroup(Box backupBox) async {
    final box = await _openBox(_workgroupBoxName);
    final existing = box.get(_systemRootId);
    if (existing == null) {
      await _backupEntry(backupBox, '001_ensure_system_workgroup', box.name,
          _systemRootId, existing);
      await box.put(_systemRootId, WorkgroupModel.systemRoot().toJson());
      return const MigrationStepResult(
        id: '001_ensure_system_workgroup',
        changedEntries: 1,
        details: {'createdSystemRoot': true},
      );
    }

    final json = _asJsonMap(existing);
    final model = WorkgroupModel.fromJson(json);
    final normalized = WorkgroupModel(
      id: _systemRootId,
      name: model.name.trim().isEmpty ? 'No Workgroup' : model.name,
      description: model.description.trim().isEmpty
          ? 'System default group'
          : model.description,
      type: model.type,
      icon: model.icon,
      isSystem: true,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );

    final nextJson = normalized.toJson();
    if (mapEquals(json, nextJson)) {
      return const MigrationStepResult(
        id: '001_ensure_system_workgroup',
        changedEntries: 0,
        details: {'createdSystemRoot': false},
      );
    }

    await _backupEntry(backupBox, '001_ensure_system_workgroup', box.name,
        _systemRootId, existing);
    await box.put(_systemRootId, nextJson);
    return const MigrationStepResult(
      id: '001_ensure_system_workgroup',
      changedEntries: 1,
      details: {'normalizedSystemRoot': true},
    );
  }

  Future<MigrationStepResult> _normalizeSavedRequests(Box backupBox) async {
    final savedBox = await _openBox(_requestBoxName);
    final workgroupIds = await _knownWorkgroupIds();
    var changedEntries = 0;
    var movedLegacyEntries = 0;

    if (Hive.isBoxOpen(_legacyRequestBoxName) ||
        await Hive.boxExists(_legacyRequestBoxName)) {
      final legacyBox = await _openBox(_legacyRequestBoxName);
      for (var i = 0; i < legacyBox.length; i++) {
        final key = legacyBox.keyAt(i);
        final value = legacyBox.get(key);
        final request = _decodeRequest(value);
        if (request == null || savedBox.containsKey(request.id)) continue;

        final normalized = _normalizeRequestGroup(request, workgroupIds);
        await _backupEntry(backupBox, '002_normalize_saved_requests',
            savedBox.name, normalized.id, null);
        await savedBox.put(normalized.id, normalized.toJson());
        movedLegacyEntries++;
        changedEntries++;
      }
    }

    for (var i = 0; i < savedBox.length; i++) {
      final key = savedBox.keyAt(i);
      final value = savedBox.get(key);
      final request = _decodeRequest(value);
      if (request == null) continue;

      final normalized = _normalizeRequestGroup(request, workgroupIds);
      final nextJson = normalized.toJson();
      final currentJson = _asJsonMap(value);

      if (mapEquals(currentJson, nextJson)) continue;

      await _backupEntry(
          backupBox, '002_normalize_saved_requests', savedBox.name, key, value);
      await savedBox.put(key, nextJson);
      changedEntries++;
    }

    return MigrationStepResult(
      id: '002_normalize_saved_requests',
      changedEntries: changedEntries,
      details: {'movedLegacyEntries': movedLegacyEntries},
    );
  }

  Future<MigrationStepResult> _normalizeWorkflows(Box backupBox) async {
    final box = await _openBox(_workflowBoxName);
    final workgroupIds = await _knownWorkgroupIds();
    var changedEntries = 0;

    for (var i = 0; i < box.length; i++) {
      final key = box.keyAt(i);
      final value = box.get(key);
      final workflow = _decodeWorkflow(value);
      if (workflow == null) continue;

      final normalized = _normalizeWorkflow(workflow, workgroupIds);
      final nextValue = jsonEncode(normalized.toJson());
      final currentValue =
          value is String ? value : jsonEncode(_asJsonMap(value));

      if (currentValue == nextValue) continue;

      await _backupEntry(
          backupBox, '003_normalize_workflows', box.name, key, value);
      await box.put(key, nextValue);
      changedEntries++;
    }

    return MigrationStepResult(
      id: '003_normalize_workflows',
      changedEntries: changedEntries,
      details: {'normalizedWorkflowSchemaVersion': 1},
    );
  }

  Future<Set<String>> _knownWorkgroupIds() async {
    final box = await _openBox(_workgroupBoxName);
    final ids = <String>{_systemRootId};
    for (var i = 0; i < box.length; i++) {
      final value = box.getAt(i);
      try {
        final json = _asJsonMap(value);
        final id = json['id'] as String?;
        if (id != null && id.trim().isNotEmpty) ids.add(id);
      } catch (_) {
        // Malformed workgroups are left untouched; repository-level parsing can
        // still surface them for manual recovery.
      }
    }
    return ids;
  }

  RequestModel? _decodeRequest(dynamic value) {
    try {
      return RequestModel.fromJson(_asJsonMap(value));
    } catch (error) {
      debugPrint('Skipping malformed request during migration: $error');
      return null;
    }
  }

  RequestModel _normalizeRequestGroup(
    RequestModel request,
    Set<String> workgroupIds,
  ) {
    final groupId = request.groupId;
    if (groupId == null ||
        groupId.trim().isEmpty ||
        !workgroupIds.contains(groupId)) {
      return request.copyWith(groupId: _systemRootId);
    }
    return request;
  }

  Workflow? _decodeWorkflow(dynamic value) {
    try {
      return Workflow.fromJson(_asJsonMap(value));
    } catch (error) {
      debugPrint('Skipping malformed workflow during migration: $error');
      return null;
    }
  }

  Workflow _normalizeWorkflow(Workflow workflow, Set<String> workgroupIds) {
    final groupId = workflow.groupId;
    final normalizedGroupId = groupId == null ||
            groupId.trim().isEmpty ||
            !workgroupIds.contains(groupId)
        ? _systemRootId
        : groupId;

    return Workflow(
      id: workflow.id,
      name: workflow.name,
      schemaVersion: WorkflowMigrationSchema.currentVersion,
      nodes: workflow.nodes.map(_normalizeWorkflowNode).toList(),
      edges: workflow.edges,
      env: workflow.env,
      groupId: normalizedGroupId,
      lastModified: workflow.lastModified,
      createdAt: workflow.createdAt,
      updatedAt: workflow.updatedAt,
    );
  }

  WorkflowNode _normalizeWorkflowNode(WorkflowNode node) {
    final data = Map<String, dynamic>.from(node.data);
    final config = _tryReadNodeConfig(node);
    if (config is EmptyNodeConfig) {
      return WorkflowNode(
        id: node.id,
        type: node.type,
        x: node.x,
        y: node.y,
        data: data,
        inputPortKeys: node.inputPortKeys,
        outputPortKeys: _defaultOutputPorts(node.type, node.outputPortKeys),
        isCompact: node.isCompact,
      );
    }

    final name = data['name'];
    final configJson = config.toJson();
    if (name != null) {
      configJson['name'] = name;
    }

    return WorkflowNode(
      id: node.id,
      type: node.type,
      x: node.x,
      y: node.y,
      data: configJson,
      inputPortKeys: node.inputPortKeys,
      outputPortKeys: _defaultOutputPorts(node.type, node.outputPortKeys),
      isCompact: node.isCompact,
    );
  }

  NodeConfig _tryReadNodeConfig(WorkflowNode node) {
    try {
      return node.config;
    } catch (error) {
      debugPrint(
        'Skipping malformed workflow node config during migration: '
        '${node.id} (${node.type}): $error',
      );
      return const EmptyNodeConfig();
    }
  }

  List<String> _defaultOutputPorts(String type, List<String> existing) {
    if (existing.isNotEmpty) return existing;
    if (type == 'end') return const [];
    if (type == 'condition') return const ['true', 'false'];
    if (type == 'api' ||
        type == 'gql_request' ||
        type == 'ws_connect' ||
        type == 'ws_send' ||
        type == 'ws_wait') {
      return const ['success', 'failure'];
    }
    return const ['output'];
  }

  Map<String, dynamic> _asJsonMap(dynamic value) {
    if (value is String) {
      return jsonDecode(value) as Map<String, dynamic>;
    }
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  }

  Future<void> _backupEntry(
    Box backupBox,
    String migrationId,
    String boxName,
    dynamic key,
    dynamic value,
  ) async {
    final backupKey =
        '$migrationId::$boxName::$key::${DateTime.now().microsecondsSinceEpoch}';
    await backupBox.put(backupKey, {
      'migrationId': migrationId,
      'boxName': boxName,
      'key': key?.toString(),
      'value': value,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Box> _openBox(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box(name);
    return Hive.openBox(name);
  }
}

class WorkflowMigrationSchema {
  static const int currentVersion = 2;
}

class MigrationRunReport {
  final DateTime startedAt;
  DateTime? finishedAt;
  final List<MigrationStepResult> applied = [];
  final List<String> skipped = [];
  final List<MigrationFailure> failed = [];

  MigrationRunReport({required this.startedAt});

  int get changedEntries =>
      applied.fold(0, (total, result) => total + result.changedEntries);

  String get summary {
    return 'Migration complete: ${applied.length} applied, '
        '${skipped.length} skipped, ${failed.length} failed, '
        '$changedEntries entries changed.';
  }
}

class MigrationFailure {
  final String migrationId;
  final String error;

  const MigrationFailure(this.migrationId, this.error);
}

class _MigrationStep {
  final String id;
  final String description;
  final Future<MigrationStepResult> Function() execute;

  const _MigrationStep({
    required this.id,
    required this.description,
    required this.execute,
  });
}

class MigrationStepResult {
  final String id;
  final int changedEntries;
  final Map<String, Object?> details;

  const MigrationStepResult({
    required this.id,
    required this.changedEntries,
    this.details = const {},
  });
}

final migrationServiceProvider = Provider<MigrationService>((ref) {
  return MigrationService();
});
