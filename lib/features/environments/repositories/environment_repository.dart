import 'package:isar/isar.dart';
import '../models/environment_item.dart';

class EnvironmentRepository {
  final Isar _isar;

  EnvironmentRepository(this._isar);

  Future<List<EnvironmentItem>> getAllEnvironments() async {
    return await _isar.environmentItems.where().findAll();
  }
  
  Future<EnvironmentItem?> getActiveEnvironment() async {
    // Assuming single active env concept persisted in DB or just local state.
    // For MVP, using isSelected flag in DB.
    return await _isar.environmentItems.filter().isSelectedEqualTo(true).findFirst();
  }

  Future<void> saveEnvironment(EnvironmentItem item) async {
    await _isar.writeTxn(() async {
      await _isar.environmentItems.put(item);
    });
  }
  
  Future<void> setActive(Id id) async {
    await _isar.writeTxn(() async {
      // Unset all
      final all = await _isar.environmentItems.where().findAll();
      for (var e in all) {
        e.isSelected = (e.id == id);
        await _isar.environmentItems.put(e);
      }
    });
  }

  Future<void> deleteEnvironment(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.environmentItems.delete(id);
    });
  }
}
