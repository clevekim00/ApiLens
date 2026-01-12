import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apilens/core/settings/settings_repository.dart';

// Simple provider for settings
// In a real app, use shared_preferences or Isar
final timeoutProvider = StateProvider<int>((ref) => 30000); // 30s default
final loggingProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeout = ref.watch(timeoutProvider);
    final logging = ref.watch(loggingProvider);
    final themeMode = ref.watch(settingsProvider);

    return Scaffold(
      key: const Key('screen_settings'),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme Mode'),
            subtitle: Text(themeMode.name.toUpperCase()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('settings_theme_light'),
                  icon: const Icon(Icons.light_mode),
                  isSelected: themeMode == ThemeMode.light,
                  onPressed: () => ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.light),
                ),
                IconButton(
                  key: const Key('settings_theme_dark'),
                  icon: const Icon(Icons.dark_mode),
                  isSelected: themeMode == ThemeMode.dark,
                  onPressed: () => ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark),
                ),
                 IconButton(
                  key: const Key('settings_theme_system'),
                  icon: const Icon(Icons.brightness_auto),
                  isSelected: themeMode == ThemeMode.system,
                  onPressed: () => ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Request Timeout (ms)'),
            subtitle: Text('$timeout ms'),
            trailing: SizedBox(
               width: 100,
               child: TextFormField(
                 initialValue: timeout.toString(),
                 keyboardType: TextInputType.number,
                 onFieldSubmitted: (val) {
                   final parsed = int.tryParse(val);
                   if (parsed != null && parsed > 0) {
                     ref.read(timeoutProvider.notifier).state = parsed;
                   }
                 },
               ),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable Logging'),
            value: logging,
            onChanged: (val) {
              ref.read(loggingProvider.notifier).state = val;
            },
          ),
        ],
      ),
    );
  }
}
