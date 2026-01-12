import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models/workgroup_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkgroupRepository {
  static const String _boxName = 'workgroups';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  List<WorkgroupModel> getAll() {
    return _box.values.map((e) {
      final json = jsonDecode(jsonEncode(e)); // Ensure map compatibility
      return WorkgroupModel.fromJson(json);
    }).toList();
  }

  List<WorkgroupModel> getByType(WorkgroupType type) {
    return getAll().where((g) => g.type == type).toList();
  }

  Future<WorkgroupModel?> getWorkgroup(String id) async {
    final data = _box.get(id);
    if (data == null) return null;
    final json = jsonDecode(jsonEncode(data));
    return WorkgroupModel.fromJson(json);
  }

  Future<void> save(WorkgroupModel workgroup) async {
    await _box.put(workgroup.id, workgroup.toJson());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}

final workgroupRepositoryProvider = Provider<WorkgroupRepository>((ref) {
  return WorkgroupRepository();
});
