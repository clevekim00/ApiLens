import 'package:apilens/core/l10n/app_localizations.dart';
import 'package:apilens/core/services/navigation_provider.dart';
import 'package:apilens/core/settings/settings_repository.dart';
import 'package:apilens/core/widgets/main_workspace_screen.dart';
import 'package:apilens/features/request/data/request_repository.dart';
import 'package:apilens/features/websocket/data/websocket_config_repository.dart';
import 'package:apilens/features/workflow_editor/data/workflow_repository.dart';
import 'package:apilens/features/workgroup/data/workgroup_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../mocks.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('main workspace navigates to Load Hub tab', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider
              .overrideWithValue(FakeSettingsRepository()),
          workgroupRepositoryProvider
              .overrideWithValue(FakeWorkgroupRepository()),
          requestRepositoryProvider.overrideWithValue(FakeRequestRepository()),
          workflowRepositoryProvider
              .overrideWithValue(FakeWorkflowRepository()),
          webSocketConfigRepositoryProvider
              .overrideWithValue(FakeWebSocketConfigRepository()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'),
            Locale('ko'),
            Locale('zh'),
          ],
          home: MainWorkspaceScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Load Hub'), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu_load_hub')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('원격 머신 2대, 원격 에이전트 2개'), findsOneWidget);
    expect(find.text('Machine Health'), findsOneWidget);
    expect(find.text('Agent Updates'), findsOneWidget);
  });

  testWidgets('navigation provider accepts Load Hub index', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(navigationProvider.notifier).setIndex(4);

    expect(container.read(navigationProvider), 4);
  });
}
