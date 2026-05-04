import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apilens/core/settings/settings_repository.dart';
import 'package:apilens/core/l10n/app_localizations.dart';

final timeoutProvider = StateProvider<int>((ref) => 30000);
final loggingProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeout = ref.watch(timeoutProvider);
    final logging = ref.watch(loggingProvider);
    final settings = ref.watch(settingsProvider);
    final themeMode = settings.themeMode;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      key: const Key('screen_settings'),
      appBar: AppBar(title: Text(l10n.translate('settings'))),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.translate('theme')),
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
            title: Text(l10n.translate('language')),
            subtitle: Text(_getLanguageName(settings.language)),
            trailing: DropdownButton<String>(
              value: settings.language,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'auto', child: Text('Auto (System)')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ko', child: Text('한국어')),
                DropdownMenuItem(value: 'zh', child: Text('中文')),
              ],
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsProvider.notifier).setLanguage(val);
                }
              },
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

  String _getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'ko': return '한국어';
      case 'zh': return '中文';
      case 'auto': return 'Auto (System)';
      default: return code;
    }
  }
}
