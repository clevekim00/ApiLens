import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/request_model.dart';
import '../models/key_value_item.dart';

class RequestRepository {
  static const String _boxName = 'saved_requests';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  List<RequestModel> getAll() {
    return _box.values.map((e) {
      // Handle potential dynamic/map issues from Hive
      final Map<String, dynamic> map = jsonDecode(jsonEncode(e));
      return _fromJson(map);
    }).toList();
  }

  Future<void> save(RequestModel request) async {
    await _box.put(request.id, _toJson(request));
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  // Helper serialization (since RequestModel doesn't have full toJson/fromJson in the viewed file)
  // Ideally should be in RequestModel, but adding here to avoid modifying Model too much if not present.
  // Wait, I should add toJson/fromJson to RequestModel properly or use this helper.
  // The viewed RequestModel code didn't show toJson/fromJson. I should probably add them or do it here.
  // Let's do it here for now to be safe, or check RequestModel again.
  // Just in case, I will implement robust mapper here.
  
  Map<String, dynamic> _toJson(RequestModel model) {
    return {
      'id': model.id,
      'name': model.name,
      'method': model.method,
      'url': model.url,
      'headers': model.headers.map((e) => e.toJson()).toList(),
      'params': model.params.map((e) => e.toJson()).toList(),
      'pathParams': model.pathParams.map((e) => e.toJson()).toList(),
      'body': model.body,
      'bodyType': model.bodyType.name,
      'authType': model.authType.name,
      'authData': model.authData,
      'groupId': model.groupId,
      'source': model.source,
    };
  }

  RequestModel _fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'],
      name: json['name'] ?? 'Saved Request',
      method: json['method'] ?? 'GET',
      url: json['url'] ?? '',
      headers: (json['headers'] as List?)?.map((e) => KeyValueItem.fromJson(e)).toList() ?? [],
      params: (json['params'] as List?)?.map((e) => KeyValueItem.fromJson(e)).toList() ?? [],
      pathParams: (json['pathParams'] as List?)?.map((e) => KeyValueItem.fromJson(e)).toList() ?? [],
      body: json['body'],
      bodyType: RequestBodyType.values.byName(json['bodyType'] ?? 'json'),
      authType: AuthType.values.byName(json['authType'] ?? 'none'),
      authData: (json['authData'] as Map?)?.cast<String, String>(),
      groupId: json['groupId'] ?? json['workgroupId'],
      source: (json['source'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  return RequestRepository();
});
