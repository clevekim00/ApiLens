import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:apilens/main.dart'; // ApiTesterApp
import 'package:apilens/core/settings/settings_repository.dart';
import 'package:apilens/features/request/data/request_repository.dart';
import 'package:apilens/features/workgroup/data/workgroup_repository.dart';
import 'package:apilens/features/workflow_editor/data/workflow_repository.dart';
import 'package:apilens/features/websocket/data/websocket_config_repository.dart';
import '../mocks.dart';

// Mock PathProvider for Hive
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.createTempSync().path;
  }
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Smoke Test: App Boot, Menu & Navigation',
      (WidgetTester tester) async {
    final settingsRepo = FakeSettingsRepository();
    final workgroupRepo = FakeWorkgroupRepository();
    final requestRepo = FakeRequestRepository();
    final workflowRepo = FakeWorkflowRepository();
    final wsRepo = FakeWebSocketConfigRepository();

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          requestRepositoryProvider.overrideWithValue(requestRepo),
          workgroupRepositoryProvider.overrideWithValue(workgroupRepo),
          workflowRepositoryProvider.overrideWithValue(workflowRepo),
          webSocketConfigRepositoryProvider.overrideWithValue(wsRepo),
        ],
        child: const ApiTesterApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    // [Smoke 1] App Boot
    expect(find.byKey(const Key('screen_request_builder')), findsOneWidget,
        reason: 'RequestScreen should be home');

    // [Smoke 2] Menu Items
    expect(find.byKey(const Key('menu_workflow')), findsOneWidget,
        reason: 'Workflow menu icon missing');
    // [Smoke 3] Request Builder Elements
    expect(find.byKey(const Key('selector_method')), findsOneWidget);
    expect(find.byKey(const Key('input_url_bar')), findsOneWidget);

    // [Smoke 4] Workflow Editor Canvas
    await tester.tap(find.byKey(const Key('menu_workflow')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('canvas_workflow')), findsOneWidget,
        reason: 'Workflow Canvas failed to load');
    expect(find.byKey(const Key('btn_canvas_fit')), findsOneWidget,
        reason: 'Workflow Canvas fit control missing');
    expect(find.byKey(const Key('canvas_minimap')), findsNothing,
        reason:
            'Workflow Canvas minimap should stay hidden for an empty workflow');
  });

  testWidgets('Smoke Test: Request sidebar collapses on narrow screens',
      (WidgetTester tester) async {
    final settingsRepo = FakeSettingsRepository();
    final workgroupRepo = FakeWorkgroupRepository();
    final requestRepo = FakeRequestRepository();
    final workflowRepo = FakeWorkflowRepository();
    final wsRepo = FakeWebSocketConfigRepository();

    tester.view.physicalSize = const Size(720, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          requestRepositoryProvider.overrideWithValue(requestRepo),
          workgroupRepositoryProvider.overrideWithValue(workgroupRepo),
          workflowRepositoryProvider.overrideWithValue(workflowRepo),
          webSocketConfigRepositoryProvider.overrideWithValue(wsRepo),
        ],
        child: const ApiTesterApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('screen_request_builder')), findsOneWidget);
    expect(find.byKey(const Key('btn_open_sidebar')), findsOneWidget);
    expect(find.byKey(const Key('selector_method')), findsOneWidget);
    expect(find.byKey(const Key('input_url_bar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_open_sidebar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('Explorer'), findsOneWidget);
    expect(find.textContaining(RegExp('History|히스토리')), findsOneWidget);
  });
}
