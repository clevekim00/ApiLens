import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/ui/theme/app_theme_light.dart';
import 'core/ui/theme/app_theme_dark.dart';
import 'core/widgets/splash_screen.dart';
import 'core/settings/settings_repository.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Initialize Settings
  final settingsRepo = SettingsRepository();
  await settingsRepo.init();

  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
      child: const ApiTesterApp(),
    ),
  );
}

class ApiTesterApp extends ConsumerWidget {
  const ApiTesterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'ApiLens',
      debugShowCheckedModeBanner: false,
      theme: AppThemeLight.themeData,
      darkTheme: AppThemeDark.themeData,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
