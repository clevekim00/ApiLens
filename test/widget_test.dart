import 'package:flutter_test/flutter_test.dart';
import 'package:apilens/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apilens/core/settings/settings_repository.dart';
import 'package:apilens/features/workgroup/data/workgroup_repository.dart';
import 'package:apilens/features/request/data/request_repository.dart';
import 'package:apilens/features/workflow_editor/data/workflow_repository.dart';
import 'package:apilens/features/websocket/data/websocket_config_repository.dart';
import 'mocks.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Override providers to avoid Hive initialization and use Fakes
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
          workgroupRepositoryProvider.overrideWithValue(FakeWorkgroupRepository()),
          requestRepositoryProvider.overrideWithValue(FakeRequestRepository()),
          workflowRepositoryProvider.overrideWithValue(FakeWorkflowRepository()),
          webSocketConfigRepositoryProvider.overrideWithValue(FakeWebSocketConfigRepository()),
        ],
        child: const ApiTesterApp(),
      ),
    );

    // Verify Splash Screen
    expect(find.byType(ApiTesterApp), findsOneWidget);
    
    // Pump to finish Splash delay (2 seconds)
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(); // Just one frame after navigation
    
    // Should be at Home/Request Screen now
    // We can just verify the app didn't crash
    expect(find.byType(ApiTesterApp), findsOneWidget);
  });
}
