import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/request/models/request_model.dart';
import '../../features/workgroup/domain/models/workgroup_model.dart';

class MigrationService {
  static const String _requestBox = 'requests';
  static const String _workgroupBox = 'workgroups';

  Future<void> run() async {
    await _migrateRequests();
  }

  Future<void> _migrateRequests() async {
    if (!Hive.isBoxOpen(_requestBox)) {
      await Hive.openBox(_requestBox);
    }
    
    final box = Hive.box(_requestBox);
    final changes = <String, RequestModel>{};

    for (var i = 0; i < box.length; i++) {
      final key = box.keyAt(i);
      final value = box.get(key);
      if (value is String) {
        try {
          final json = jsonDecode(value) as Map<String, dynamic>;
          
          // Check if groupId is missing or explicitly null
          // Note: RequestModel.fromJson handles 'workgroupId' alias, so if we use fromJson -> toJson, it might normalize it.
          // BUT, if we want to force 'no-workgroup' for nulls:
          final model = RequestModel.fromJson(json);
          
          if (model.groupId == null) {
            final migrated = model.copyWith(groupId: 'no-workgroup');
            changes[key] = migrated;
          }
        } catch (e) {
          print('Migration Error for $key: $e');
        }
      }
    }

    if (changes.isNotEmpty) {
      print('Migrating ${changes.length} requests to "no-workgroup"...');
      for (final entry in changes.entries) {
        await box.put(entry.key, jsonEncode(entry.value.toJson()));
      }
    }
  }
}

final migrationServiceProvider = Provider<MigrationService>((ref) {
  return MigrationService();
});
