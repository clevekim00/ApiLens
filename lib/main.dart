import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/splash_screen.dart';


import 'features/websocket/data/websocket_config_repository.dart'; // import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  // Seed Defaults
  await WebSocketConfigRepository().ensureSeeded();
  
  runApp(
    const ProviderScope(
      child: ApiTesterApp(),
    ),
  );
}

class ApiTesterApp extends StatelessWidget {
  const ApiTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ApiLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
