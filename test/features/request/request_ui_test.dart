import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apilens/features/request/screens/request_screen.dart';
import 'package:apilens/features/request/data/request_repository.dart';
import 'package:apilens/core/settings/settings_repository.dart';
import 'package:apilens/features/workgroup/data/workgroup_repository.dart';
import 'package:apilens/features/workflow_editor/data/workflow_repository.dart';
import 'package:apilens/features/websocket/data/websocket_config_repository.dart';
import 'package:apilens/features/history/providers/history_provider.dart';
import 'package:apilens/features/workgroup/application/workgroup_controller.dart';
import 'package:apilens/features/response/providers/response_provider.dart';
import 'package:apilens/core/network/models/response_model.dart';
import 'package:apilens/features/history/models/history_item.dart';
import '../../mocks.dart';

class MockHistoryNotifier extends HistoryNotifier {
  @override
  Future<List<HistoryItem>> build() async => [];
}

class MockResponseNotifier extends ResponseNotifier {
  @override
  AsyncValue<ResponseModel?> build() => const AsyncData(null);
}

void main() {
  group('RequestScreen UI Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
          workgroupRepositoryProvider.overrideWithValue(FakeWorkgroupRepository()),
          requestRepositoryProvider.overrideWithValue(FakeRequestRepository()),
          workflowRepositoryProvider.overrideWithValue(FakeWorkflowRepository()),
          webSocketConfigRepositoryProvider.overrideWithValue(FakeWebSocketConfigRepository()),
          activeWorkgroupIdProvider.overrideWith((ref) => 'test-group'),
          historyNotifierProvider.overrideWith(() => MockHistoryNotifier()),
          responseNotifierProvider.overrideWith(() => MockResponseNotifier()),
        ],
      );
    });

    testWidgets('RequestScreen renders key components', (WidgetTester tester) async {
      // Use a larger default size to avoid overflows in tests
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RequestScreen(),
          ),
        ),
      );

      // Verify basic rendering
      expect(find.text('HTTP / REST'), findsOneWidget);
      expect(find.byKey(const Key('input_url_bar')), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);

      tester.view.resetPhysicalSize();
    });
  });
}
