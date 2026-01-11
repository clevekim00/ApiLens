
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsRepository {
  static const String _boxName = 'settings_box';
  static const String _themeKey = 'theme_mode';
  
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  ThemeMode getThemeMode() {
    final value = _box.get(_themeKey);
    if (value == 'light') return ThemeMode.light;
    if (value == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String value = 'system';
    if (mode == ThemeMode.light) value = 'light';
    if (mode == ThemeMode.dark) value = 'dark';
    await _box.put(_themeKey, value);
  }
}

// Global Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

// StateNotifier for reactivity
class SettingsController extends StateNotifier<ThemeMode> {
  final SettingsRepository _repository;

  SettingsController(this._repository) : super(_repository.getThemeMode());

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(mode);
    state = mode;
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, ThemeMode>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsController(repo);
});
