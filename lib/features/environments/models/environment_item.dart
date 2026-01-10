import 'package:isar/isar.dart';

part 'environment_item.g.dart';

@collection
class EnvironmentItem {
  Id id = Isar.autoIncrement;

  late String name;
  
  // Storing variables as JSON string: {"baseUrl": "http://...", "token": "xyz"}
  late String variablesJson;

  @Index()
  bool isSelected = false; // Simple way to track active env in DB
}
