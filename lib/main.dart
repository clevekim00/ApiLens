import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/ui/theme/app_theme_light.dart';
import 'core/ui/theme/app_theme_dark.dart';
import 'core/widgets/splash_screen.dart';
import 'core/settings/settings_repository.dart';

import 'features/websocket/data/websocket_config_repository.dart';
import 'features/workgroup/data/workgroup_repository.dart';
import 'features/request/data/request_repository.dart';
import 'features/workflow_editor/data/workflow_repository.dart';
import 'features/workflow_editor/data/workflow_storage.dart';
import 'features/workflow_editor/domain/models/workflow_node.dart';
import 'features/workflow_editor/domain/models/workflow_edge.dart';
import 'core/data/migration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  _registerHiveAdapters();

  // Initialize Settings
  final settingsRepo = SettingsRepository();
  await settingsRepo.init();

  // Initialize Data Layer (Hive Boxes)
  final workgroupRepo = WorkgroupRepository();
  await workgroupRepo.init();

  final requestRepo = RequestRepository();
  await requestRepo.init();

  final workflowRepo = WorkflowRepository(WorkflowStorage());

  final wsConfigRepo = WebSocketConfigRepository();

  // Run Migrations (Seed & Fix Data)
  await MigrationService().run();

  // Seed Defaults
  await wsConfigRepo.ensureSeeded();

  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        workgroupRepositoryProvider.overrideWithValue(workgroupRepo),
        requestRepositoryProvider.overrideWithValue(requestRepo),
        workflowRepositoryProvider.overrideWithValue(workflowRepo),
        webSocketConfigRepositoryProvider.overrideWithValue(wsConfigRepo),
      ],
      child: const ApiTesterApp(),
    ),
  );
}

void _registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(WorkflowNodeAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(WorkflowEdgeAdapter());
  }
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
