import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/websocket_config.dart';

class WebSocketConfigRepository {
  static const String boxName = 'websocket_configs';
  
  // Hive Box (Lazy initialization or passed in)
  // For simplicity using Hive.box directly implies it needs valid open call.
  // Better to ensure openBox is called before usage.
  
  Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<Map>(boxName);
    }
    return Hive.box<Map>(boxName);
  }

  Future<List<WebSocketConfig>> getAll() async {
    final box = await _getBox();
    if (box.isEmpty) return [];

    return box.values.map((data) {
      // Cast to Map<String, dynamic> safely
      final map = Map<String, dynamic>.from(data);
      return WebSocketConfig.fromJson(map);
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Descending sort
  }

  Future<WebSocketConfig?> get(String id) async {
    final box = await _getBox();
    final data = box.get(id);
    if (data == null) return null;
    return WebSocketConfig.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> save(WebSocketConfig config) async {
    final box = await _getBox();
    await box.put(config.id, config.toJson());
  }

  Future<WebSocketConfig> saveNew({required String name, required String url}) async {
    final newConfig = WebSocketConfig(
      id: const Uuid().v4(),
      name: name,
      url: url,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      headers: {},
      protocols: [],
      autoReconnect: false,
      reconnect: const WebSocketReconnectConfig(maxAttempts: 3, backoffMs: 1000),
    );
    await save(newConfig);
    return newConfig;
  }

  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<WebSocketConfig> duplicate(String id) async {
    final config = await get(id);
    if (config == null) throw Exception('Config not found: $id');

    // config.copyWith follows original ID, so we manually reconstruct to ensure new ID.
    // Overwrite ID and dates
    // Since copyWith follows original ID, we need to create a new instance essentially or Force ID.
    // copyWith in domain model usually keeps ID.
    // Let's manually reconstruct or add copyWithId.
    // Or just modify copyWith in generic way? 
    // Domain model implies entity identity.
    // Let's create new instance from properties.
    final duplicated = WebSocketConfig(
      id: const Uuid().v4(), // New ID
      name: '${config.name} (Copy)',
      url: config.url,
      protocols: List.from(config.protocols),
      headers: Map.from(config.headers),
      auth: config.auth, // Immutable
      autoReconnect: config.autoReconnect,
      reconnect: config.reconnect,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await save(duplicated);
    return duplicated;
  }
  Future<void> ensureSeeded() async {
    final box = await _getBox();
    if (box.isEmpty) {
      // Seed sample config
      final echoConfig = WebSocketConfig(
        id: const Uuid().v4(),
        name: 'Echo Test (Public)',
        url: 'wss://echo.websocket.org',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        headers: {},
        protocols: [],
        autoReconnect: false,
        reconnect: const WebSocketReconnectConfig(maxAttempts: 3, backoffMs: 1000),
      );
      
      final localConfig = WebSocketConfig(
        id: const Uuid().v4(),
        name: 'Local Dev (Placeholder)',
        url: 'ws://localhost:8080/ws',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        headers: {},
        protocols: [],
        autoReconnect: true,
        reconnect: const WebSocketReconnectConfig(maxAttempts: 5, backoffMs: 500),
      );

      await save(echoConfig);
      await save(localConfig);
      print('WebSocket Configs seeded.');
    }
  }
}

final webSocketConfigRepositoryProvider = Provider<WebSocketConfigRepository>((ref) {
  return WebSocketConfigRepository();
});
