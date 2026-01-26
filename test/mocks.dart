import 'package:apilens/features/request/data/request_repository.dart';
import 'package:apilens/features/request/models/request_model.dart';
import 'package:hive/hive.dart';
import 'package:apilens/features/workflow_editor/data/workflow_repository.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow_model.dart';
import 'package:apilens/features/workgroup/data/workgroup_repository.dart';
import 'package:apilens/features/workgroup/domain/models/workgroup_model.dart';
import 'package:apilens/core/settings/settings_repository.dart';
import 'package:apilens/features/websocket/data/websocket_config_repository.dart';

import 'package:apilens/features/websocket/domain/models/websocket_config.dart';
import 'package:flutter/material.dart';

class FakeRequestRepository implements RequestRepository {
   @override
   late Box<RequestModel> _box;
   
   @override
   Future<void> init() async {}
   @override
   List<RequestModel> getAll() => [];
   @override
   Future<void> save(RequestModel request) async {}
   @override
   Future<void> delete(String id) async {}
   @override
   Future<void> clear() async {}
   @override
   List<RequestModel> getByGroup(String groupId) => [];
   @override
   RequestModel? get(String id) => null;
}

class FakeWorkflowRepository implements WorkflowRepository {
    @override
    late Box<WorkflowModel> _box; // Mock var to satisfy field if any, but implementation hides it.

    @override
    Future<void> init() async {}
    
    @override
    List<WorkflowModel> getAll() => [];
    
    @override 
    List<WorkflowModel> getByGroup(String groupId) => [];

    @override
    WorkflowModel? get(String id) => null;

    @override
    Future<void> save(WorkflowModel workflow) async {}

    @override
    Future<void> delete(String id) async {}

    @override
    Future<void> clear() async {}

    @override
    String exportJson(WorkflowModel workflow) => "{}";

    @override
    WorkflowModel importJson(String jsonStr) => WorkflowModel(id: 'stub', name: 'stub', lastSavedAt: DateTime.now());
}

class FakeWorkgroupRepository implements WorkgroupRepository {
    @override
    late Box _box;

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

class FakeSettingsRepository implements SettingsRepository {
  @override
  Future<void> init() async {}
  
  @override
  ThemeMode getThemeMode() => ThemeMode.system;
  
  @override 
  Future<void> setThemeMode(ThemeMode mode) async {}
  
  @override
  String? getLastSelectedWsConfigId() => null;
  
  @override
  Future<void> setLastSelectedWsConfigId(String id) async {}
} 

class FakeWebSocketConfigRepository implements WebSocketConfigRepository {
  @override
  Future<List<WebSocketConfig>> getAll() async => [];
  @override
  Future<WebSocketConfig?> get(String id) async => null;
  @override
  Future<void> save(WebSocketConfig config) async {}
  @override
  Future<WebSocketConfig> saveNew({required String name, required String url}) async {
    return WebSocketConfig(id: 'test', name: name, url: url, createdAt: DateTime.now(), updatedAt: DateTime.now());
  }
  @override
  Future<void> delete(String id) async {}
  @override
  Future<WebSocketConfig> duplicate(String id) async {
     return WebSocketConfig(id: 'dup', name: 'dup', url: '', createdAt: DateTime.now(), updatedAt: DateTime.now());
  }
  @override
  Future<void> ensureSeeded() async {}
}
