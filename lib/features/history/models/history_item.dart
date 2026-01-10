import 'package:isar/isar.dart';

part 'history_item.g.dart';

@collection
class HistoryItem {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime createdAt;

  late String method;
  late String url;
  
  // Storing complex objects as JSON strings for simplicity in Isar
  late String headersJson; 
  late String paramsJson;
  late String? body;
  late String authJson;

  late int statusCode;
  late int durationMs;

  // Search helpers
  @Index(type: IndexType.value, caseSensitive: false)
  List<String> get searchTerms => [url, method];
}
