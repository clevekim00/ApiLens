import 'package:isar/isar.dart';
import '../models/history_item.dart';

class HistoryRepository {
  final Isar _isar;

  HistoryRepository(this._isar);

  Future<void> addHistory(HistoryItem item) async {
    await _isar.writeTxn(() async {
      await _isar.historyItems.put(item);
    });
  }

  Future<List<HistoryItem>> getHistory({String? query, int limit = 50}) async {
    if (query != null && query.isNotEmpty) {
      return await _isar.historyItems
          .filter()
          .urlContains(query, caseSensitive: false)
          .or()
          .methodContains(query, caseSensitive: false)
          .sortByCreatedAtDesc()
          .limit(limit)
          .findAll();
    } else {
      return await _isar.historyItems
          .where()
          .sortByCreatedAtDesc()
          .limit(limit)
          .findAll();
    }
  }

  Future<void> clearHistory() async {
    await _isar.writeTxn(() async {
      await _isar.historyItems.clear();
    });
  }

  Future<void> deleteHistory(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.historyItems.delete(id);
    });
  }
}
