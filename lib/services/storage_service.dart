import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/http_request_model.dart';

class StorageService {
  static const String _historyKey = 'request_history';
  static const int _maxHistoryItems = 50;

  // Save request to history
  Future<void> saveToHistory(HttpRequestModel request) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    // Add new request to the beginning
    history.insert(0, request);

    // Limit history size
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    // Save to storage
    final jsonList = history.map((req) => req.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  // Get request history
  Future<List<HttpRequestModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => HttpRequestModel.fromJson(json))
          .toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  // Delete a specific request from history
  Future<void> deleteFromHistory(String requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    history.removeWhere((req) => req.id == requestId);

    final jsonList = history.map((req) => req.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  // Clear all history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // Search history by name or URL
  Future<List<HttpRequestModel>> searchHistory(String query) async {
    final history = await getHistory();

    if (query.isEmpty) {
      return history;
    }

    final lowerQuery = query.toLowerCase();
    return history.where((req) {
      return req.name.toLowerCase().contains(lowerQuery) ||
          req.url.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // ===== Collection Storage =====

  static const String _collectionsKey = 'collections_metadata';

  // Save collections metadata (list of collection IDs and names)
  Future<void> saveCollectionsMetadata(
    List<Map<String, String>> collectionsMetadata,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_collectionsKey, jsonEncode(collectionsMetadata));
  }

  // Get collections metadata
  Future<List<Map<String, String>>> getCollectionsMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_collectionsKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => Map<String, String>.from(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Save last active collection ID
  Future<void> saveLastActiveCollectionId(String? collectionId) async {
    final prefs = await SharedPreferences.getInstance();
    if (collectionId == null) {
      await prefs.remove('last_active_collection_id');
    } else {
      await prefs.setString('last_active_collection_id', collectionId);
    }
  }

  // Get last active collection ID
  Future<String?> getLastActiveCollectionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_active_collection_id');
  }
}
