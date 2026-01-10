import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/database_provider.dart';
import '../models/history_item.dart';
import '../repositories/history_repository.dart';

part 'history_provider.g.dart';

@riverpod
HistoryRepository historyRepository(HistoryRepositoryRef ref) {
  // We need the Isar instance initialized
  final isar = ref.watch(isarDatabaseProvider).valueOrNull;
  if (isar == null) throw UnimplementedError('Database not initialized');
  return HistoryRepository(isar);
}

@riverpod
class HistoryNotifier extends _$HistoryNotifier {
  @override
  Future<List<HistoryItem>> build() async {
    // Initial load
    final repo = ref.watch(historyRepositoryProvider);
    return repo.getHistory();
  }

  Future<void> addToHistory(HistoryItem item) async {
    final repo = ref.read(historyRepositoryProvider);
    await repo.addHistory(item);
    // Refresh list
    ref.invalidateSelf();
  }

  Future<void> search(String query) async {
    final repo = ref.read(historyRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repo.getHistory(query: query));
  }

  Future<void> deleteHistory(Id id) async {
    final repo = ref.read(historyRepositoryProvider);
    await repo.deleteHistory(id);
    ref.invalidateSelf();
  }
}
