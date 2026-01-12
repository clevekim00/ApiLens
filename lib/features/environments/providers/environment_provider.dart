import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../core/database/database_provider.dart';
import '../models/environment_item.dart';
import '../repositories/environment_repository.dart';

part 'environment_provider.g.dart';

@riverpod
Future<EnvironmentRepository> environmentRepository(EnvironmentRepositoryRef ref) async {
  final isar = await ref.watch(isarDatabaseProvider.future);
  return EnvironmentRepository(isar);
}

@riverpod
class ActiveEnvironmentId extends _$ActiveEnvironmentId {
  @override
  Id? build() {
    return null; // Initial null
  }
  
  void set(Id? id) => state = id;
}

@riverpod
class EnvironmentList extends _$EnvironmentList {
  @override
  Future<List<EnvironmentItem>> build() async {
    final repo = await ref.watch(environmentRepositoryProvider.future);
    final list = await repo.getAllEnvironments();
    
    // Sync active ID state
    final active = list.where((e) => e.isSelected).firstOrNull;
    if (active != null) {
      Future(() {
        if(ref.exists(activeEnvironmentIdProvider)) {
            ref.read(activeEnvironmentIdProvider.notifier).set(active.id);
        }
      });
    }
    
    return list;
  }

  Future<void> addEnvironment(String name) async {
    final repo = await ref.read(environmentRepositoryProvider.future);
    final newItem = EnvironmentItem()
      ..name = name
      ..variablesJson = '{}'
      ..isSelected = false;
    await repo.saveEnvironment(newItem);
    ref.invalidateSelf();
  }
  
  Future<void> updateEnvironment(Id id, String name, Map<String, String> variables) async {
     final repo = await ref.read(environmentRepositoryProvider.future);
     final item = EnvironmentItem()
       ..id = id
       ..name = name
       ..variablesJson = jsonEncode(variables)
       ..isSelected = ref.read(activeEnvironmentIdProvider) == id; 
     
     await repo.saveEnvironment(item);
     ref.invalidateSelf();
  }

  Future<void> activateEnvironment(Id? id) async {
    final repo = await ref.read(environmentRepositoryProvider.future);
    if (id != null) {
      await repo.setActive(id);
    }
    ref.read(activeEnvironmentIdProvider.notifier).set(id);
    ref.invalidateSelf(); // Refresh list to update checkbox in UI if we show it
  }

  Future<void> deleteEnvironment(Id id) async {
    final repo = await ref.read(environmentRepositoryProvider.future);
    await repo.deleteEnvironment(id);
    if (ref.read(activeEnvironmentIdProvider) == id) {
       ref.read(activeEnvironmentIdProvider.notifier).set(null);
    }
    ref.invalidateSelf();
  }
}
