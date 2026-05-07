import 'dart:io';

import 'package:apilens/core/settings/settings_repository.dart';
import 'package:apilens/features/import/application/openapi_import_controller.dart';
import 'package:apilens/features/import/presentation/screens/openapi_import_screen.dart';
import 'package:apilens/features/request/data/request_repository.dart';
import 'package:apilens/features/websocket/data/websocket_config_repository.dart';
import 'package:apilens/features/workflow_editor/data/workflow_repository.dart';
import 'package:apilens/features/workgroup/data/workgroup_repository.dart';
import 'package:apilens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mocks.dart';

class _MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.createTempSync().path;
  }
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = _MockPathProviderPlatform();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Request shell renders across common screen sizes', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const sizes = [
      Size(390, 844),
      Size(768, 1024),
      Size(1280, 800),
      Size(1440, 900),
    ];

    for (final size in sizes) {
      await _setSurface(tester, size);
      await tester.pumpWidget(_appWithFakes());
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('screen_request_builder')),
        findsOneWidget,
        reason: 'Request screen should render at ${size.width}x${size.height}',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'No Flutter exception expected at ${size.width}x${size.height}',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('OpenAPI import preview layout adapts across screen sizes', (
    WidgetTester tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const sizes = [
      Size(390, 844),
      Size(768, 1024),
      Size(1280, 800),
      Size(1440, 900),
    ];

    for (final size in sizes) {
      await _setSurface(tester, size);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OpenApiImportScreen(targetGroupId: 'qa-group'),
          ),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(OpenApiImportScreen)),
      );
      await container
          .read(openApiImportControllerProvider.notifier)
          .loadContent(_sampleOpenApiSpec);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('openapi_operation_table')), findsOne);
      expect(find.byKey(const ValueKey('openapi_operation_preview')), findsOne);
      expect(find.text('/users'), findsAtLeastNWidgets(1));
      final exception = tester.takeException();
      if (exception is FlutterError) {
        // ignore: avoid_print
        print(exception.toStringDeep());
      }
      expect(
        exception,
        isNull,
        reason:
            'OpenAPI import should not overflow at ${size.width}x${size.height}',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
}

Widget _appWithFakes() {
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
      requestRepositoryProvider.overrideWithValue(FakeRequestRepository()),
      workgroupRepositoryProvider.overrideWithValue(FakeWorkgroupRepository()),
      workflowRepositoryProvider.overrideWithValue(FakeWorkflowRepository()),
      webSocketConfigRepositoryProvider.overrideWithValue(
        FakeWebSocketConfigRepository(),
      ),
    ],
    child: const ApiTesterApp(),
  );
}

const _sampleOpenApiSpec = '''
{
  "openapi": "3.0.3",
  "info": {
    "title": "QA Petstore",
    "version": "1.2.0"
  },
  "servers": [
    { "url": "https://api.example.com" }
  ],
  "paths": {
    "/users": {
      "get": {
        "summary": "List users",
        "operationId": "listUsers",
        "tags": ["Users"],
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "schema": { "type": "integer" }
          }
        ],
        "security": [{ "bearerAuth": [] }]
      },
      "post": {
        "summary": "Create user",
        "operationId": "createUser",
        "tags": ["Users"],
        "requestBody": {
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "name": { "type": "string" }
                }
              }
            }
          }
        }
      }
    },
    "/teams/{teamId}": {
      "delete": {
        "summary": "Delete team",
        "operationId": "deleteTeam",
        "tags": ["Teams"],
        "parameters": [
          {
            "name": "teamId",
            "in": "path",
            "required": true,
            "schema": { "type": "string" }
          }
        ]
      }
    }
  }
}
''';
