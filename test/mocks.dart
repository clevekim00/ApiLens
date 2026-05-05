import 'package:flutter/material.dart';

import 'package:apilens/core/settings/settings_repository.dart';
import 'package:apilens/features/request/data/request_repository.dart';
import 'package:apilens/features/request/models/request_model.dart';
import 'package:apilens/features/websocket/data/websocket_config_repository.dart';
import 'package:apilens/features/websocket/domain/models/websocket_config.dart';
import 'package:apilens/features/workflow_editor/data/workflow_repository.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow.dart';
import 'package:apilens/features/workgroup/data/workgroup_repository.dart';
import 'package:apilens/features/workgroup/domain/models/workgroup_model.dart';

class FakeSettingsRepository implements SettingsRepository {
  @override
  Future<void> init() async {}

  @override
  ThemeMode getThemeMode() => ThemeMode.system;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}

  @override
  String getLanguage() => 'en';

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  bool getHasSeenTutorial() => true;

  @override
  Future<void> setHasSeenTutorial(bool value) async {}

  @override
  String? getLastSelectedWsConfigId() => null;

  @override
  Future<void> setLastSelectedWsConfigId(String id) async {}
}

class FakeWorkgroupRepository implements WorkgroupRepository {
  @override
  Future<void> init() async {}

  @override
  List<WorkgroupModel> getAll() => [];

  @override
  List<WorkgroupModel> getByType(WorkgroupType type) => [];

  @override
  Future<WorkgroupModel?> getWorkgroup(String id) async => null;

  @override
  Future<void> save(WorkgroupModel workgroup) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clear() async {}
}

class FakeRequestRepository implements RequestRepository {
  @override
  Future<void> init() async {}

  @override
  List<RequestModel> getAll() => [];

  @override
  Future<void> save(RequestModel request) async {}

  @override
  Future<void> delete(String id) async {}
}

class FakeWorkflowRepository implements WorkflowRepository {
  @override
  Future<void> save(Workflow workflow) async {}

  @override
  Future<List<Workflow>> getAll() async => [];

  @override
  Future<void> delete(String id) async {}

  @override
  String exportJson(Workflow workflow) => '{}';

  @override
  Workflow importJson(String jsonString) => Workflow(
        id: 'stub',
        name: 'stub',
        nodes: const [],
        edges: const [],
      );
}

class FakeWebSocketConfigRepository implements WebSocketConfigRepository {
  @override
  Future<List<WebSocketConfig>> getAll() async => [];

  @override
  Future<WebSocketConfig?> get(String id) async => null;

  @override
  Future<void> save(WebSocketConfig config) async {}

  @override
  Future<WebSocketConfig> saveNew({
    required String name,
    required String url,
  }) async {
    return WebSocketConfig(
      id: 'test',
      name: name,
      url: url,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<WebSocketConfig> duplicate(String id) async {
    return WebSocketConfig(
      id: 'dup',
      name: 'dup',
      url: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> ensureSeeded() async {}
}
