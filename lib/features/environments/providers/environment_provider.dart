import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../core/database/database_provider.dart';
import '../models/environment_item.dart';
import '../repositories/environment_repository.dart';

part 'environment_provider.g.dart';

@riverpod
EnvironmentRepository environmentRepository(EnvironmentRepositoryRef ref) {
  final isar = ref.watch(isarDatabaseProvider).valueOrNull;
  if (isar == null) throw UnimplementedError('DB not ready');
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
    final repo = ref.watch(environmentRepositoryProvider);
    final list = await repo.getAllEnvironments();
    
    // Sync active ID state
    final active = list.where((e) => e.isSelected).firstOrNull;
    if (active != null) {
      // Avoid modifying provider during build by delaying or assuming UI will read DB active state.
      // Better: User `ref.read(activeEnvironmentIdProvider.notifier).set(active.id)` in a Side Effect
      // or just assume this provider manages the source of truth for list.
      // Let's use `ref.read` in a microtask if needed, or just let UI Initialize it.
      // For simplicity: We will set it immediately if possible via ref.notify listeners? No.
      Future(() {
        if(ref.exists(activeEnvironmentIdProvider)) {
            ref.read(activeEnvironmentIdProvider.notifier).set(active.id);
        }
      });
    }
    
    return list;
  }

  Future<void> addEnvironment(String name) async {
    final repo = ref.read(environmentRepositoryProvider);
    final newItem = EnvironmentItem()
      ..name = name
      ..variablesJson = '{}'
      ..isSelected = false;
    await repo.saveEnvironment(newItem);
    ref.invalidateSelf();
  }
  
  Future<void> updateEnvironment(Id id, String name, Map<String, String> variables) async {
     final repo = ref.read(environmentRepositoryProvider);
     final item = EnvironmentItem()
       ..id = id
       ..name = name
       ..variablesJson = jsonEncode(variables)
       // Preserve active state? Or re-read. Simple is overwrite with explicit ID.
       // We should fetch original to keep isSelected or pass it in. 
       // For MVP assume repository handles it or we simply persist isSelected from current knowledge.
       // Actually `put` overwrites. We need to respect `isSelected`.
       ..isSelected = ref.read(activeEnvironmentIdProvider) == id; 
     
     await repo.saveEnvironment(item);
     ref.invalidateSelf();
  }

  Future<void> activateEnvironment(Id? id) async {
    final repo = ref.read(environmentRepositoryProvider);
    if (id != null) {
      await repo.setActive(id);
    }
    ref.read(activeEnvironmentIdProvider.notifier).set(id);
    ref.invalidateSelf(); // Refresh list to update checkbox in UI if we show it
  }

  Future<void> deleteEnvironment(Id id) async {
    final repo = ref.read(environmentRepositoryProvider);
    await repo.deleteEnvironment(id);
    if (ref.read(activeEnvironmentIdProvider) == id) {
       ref.read(activeEnvironmentIdProvider.notifier).set(null);
    }
    ref.invalidateSelf();
  }
}
