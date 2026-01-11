import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsRepository {
  static const String boxName = 'settings';
  static const String keyLastWsConfigId = 'lastSelectedWsConfigId';
  static const String keyThemeMode = 'themeMode';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<String?> getLastSelectedWsConfigId() async {
    final box = await _getBox();
    return box.get(keyLastWsConfigId) as String?;
  }

  Future<void> setLastSelectedWsConfigId(String id) async {
    final box = await _getBox();
    await box.put(keyLastWsConfigId, id);
  }

  Future<ThemeMode> getThemeMode() async {
    final box = await _getBox();
    final index = box.get(keyThemeMode) as int?;
    if (index == null) return ThemeMode.system;
    return ThemeMode.values[index];
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final box = await _getBox();
    await box.put(keyThemeMode, mode.index);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});
