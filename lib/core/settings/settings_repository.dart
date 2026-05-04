import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsRepository {
  static const String _boxName = 'settings_box';
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _lastWsConfigIdKey = 'last_selected_ws_config_id';
  
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  // --- Theme ---
  ThemeMode getThemeMode() {
    if (!_box.isOpen) return ThemeMode.dark;
    final value = _box.get(_themeKey, defaultValue: 'dark') as String;
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

  // --- Language ---
  String getLanguage() {
    if (!_box.isOpen) return 'en';
    // Default to platform language if not set, handled by controller
    return _box.get(_languageKey) as String? ?? 'auto';
  }

  Future<void> setLanguage(String languageCode) async {
    await _box.put(_languageKey, languageCode);
  }

  // --- WebSocket ---
  String? getLastSelectedWsConfigId() {
    if (!_box.isOpen) return null;
    return _box.get(_lastWsConfigIdKey) as String?;
  }

  Future<void> setLastSelectedWsConfigId(String id) async {
    await _box.put(_lastWsConfigIdKey, id);
  }
}

// Global Provider
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

// State classes for settings
class SettingsState {
  final ThemeMode themeMode;
  final String language;

  SettingsState({required this.themeMode, required this.language});

  SettingsState copyWith({ThemeMode? themeMode, String? language}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }
}

// StateNotifier for reactivity
class SettingsController extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;

  SettingsController(this._repository)
      : super(SettingsState(
          themeMode: _repository.getThemeMode(),
          language: _repository.getLanguage(),
        ));

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLanguage(String languageCode) async {
    await _repository.setLanguage(languageCode);
    state = state.copyWith(language: languageCode);
  }

  Locale? getLocale() {
    if (state.language == 'auto') return null;
    return Locale(state.language);
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsController(repo);
});
