import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// We will add schemas here as we create them
import '../../features/history/models/history_item.dart';
import '../../features/environments/models/environment_item.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
Future<Isar> isarDatabase(IsarDatabaseRef ref) async {
  final dir = await getApplicationDocumentsDirectory();
  
  if (Isar.instanceNames.isEmpty) {
    return await Isar.open(
      [
        HistoryItemSchema,
        EnvironmentItemSchema,
      ],
      directory: dir.path,
    );
  }
  
  return Isar.getInstance()!;
}
