import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models/graphql_request_config.dart';

class GraphQLRequestRepository {
  static const String boxName = 'graphql_requests';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<void> save(GraphQLRequestConfig config) async {
    final box = await _getBox();
    await box.put(config.id, jsonEncode(config.toJson()));
  }

  Future<GraphQLRequestConfig?> get(String id) async {
    final box = await _getBox();
    final jsonStr = box.get(id);
    if (jsonStr == null) return null;
    return GraphQLRequestConfig.fromJson(jsonDecode(jsonStr));
  }

  Future<List<GraphQLRequestConfig>> getAll() async {
    final box = await _getBox();
    final List<GraphQLRequestConfig> list = [];
    for (var key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          list.add(GraphQLRequestConfig.fromJson(jsonDecode(jsonStr)));
        } catch (e) {
          // Skip malformed
        }
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Descending
    return list;
  }

  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}

final graphQLRepositoryProvider = Provider<GraphQLRequestRepository>((ref) {
  return GraphQLRequestRepository();
});
