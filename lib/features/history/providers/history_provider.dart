import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../models/history_item.dart';
import '../repositories/history_repository.dart';

part 'history_provider.g.dart';

@riverpod
Future<HistoryRepository> historyRepository(HistoryRepositoryRef ref) async {
  final isar = await ref.watch(isarDatabaseProvider.future);
  return HistoryRepository(isar);
}

@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  @override
  Future<List<HistoryItem>> build() async {
    final repo = await ref.watch(historyRepositoryProvider.future);
    return repo.getHistory();
  }

  Future<void> addToHistory(HistoryItem item) async {
    final repo = await ref.read(historyRepositoryProvider.future);
    await repo.addHistory(item);
    // Refresh list
    ref.invalidateSelf();
  }

  Future<void> search(String query) async {
    final repo = await ref.read(historyRepositoryProvider.future);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.getHistory(query: query));
  }

  Future<void> deleteHistory(Id id) async {
    final repo = await ref.read(historyRepositoryProvider.future);
    await repo.deleteHistory(id);
    ref.invalidateSelf();
  }
}
