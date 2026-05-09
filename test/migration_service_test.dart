import 'dart:convert';
import 'dart:io';

import 'package:apilens/core/data/migration_service.dart';
import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('apilens_migration_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('creates system workgroup and normalizes saved request group links',
      () async {
    final savedRequests = await Hive.openBox('saved_requests');
    await savedRequests.put('req-1', {
      'id': 'req-1',
      'name': 'Orphan Request',
      'method': 'GET',
      'url': 'https://example.com',
      'workgroupId': 'missing-group',
    });

    final report = await MigrationService().run();

    final workgroups = Hive.box('workgroups');
    expect(workgroups.containsKey('no-workgroup'), isTrue);

    final migratedRequest =
        Map<String, dynamic>.from(savedRequests.get('req-1') as Map);
    expect(migratedRequest['groupId'], 'no-workgroup');
    expect(migratedRequest.containsKey('workgroupId'), isFalse);
    expect(report.applied, hasLength(3));
    expect(report.changedEntries, greaterThanOrEqualTo(2));
  });

  test('moves legacy requests into saved request box once', () async {
    final legacyRequests = await Hive.openBox('requests');
    await legacyRequests.put(
      'legacy-key',
      jsonEncode({
        'id': 'legacy-1',
        'name': 'Legacy Request',
        'method': 'POST',
        'url': 'https://example.com/legacy',
      }),
    );

    await MigrationService().run();
    final savedRequests = Hive.box('saved_requests');
    expect(savedRequests.containsKey('legacy-1'), isTrue);
    expect(
      Map<String, dynamic>.from(
          savedRequests.get('legacy-1') as Map)['groupId'],
      'no-workgroup',
    );

    final secondReport = await MigrationService().run();
    expect(secondReport.applied, isEmpty);
    expect(secondReport.skipped, contains('002_normalize_saved_requests'));
  });

  test('normalizes workflows with fallback group and execution policy defaults',
      () async {
    final workflows = await Hive.openBox('workflows_box');
    await workflows.put(
      'wf-1',
      jsonEncode({
        'id': 'wf-1',
        'name': 'Legacy Workflow',
        'schemaVersion': 1,
        'groupId': 'missing-group',
        'nodes': [
          {
            'id': 'start',
            'type': 'start',
            'x': 0,
            'y': 0,
            'data': {'name': 'Start'},
            'outputs': ['out'],
          },
          {
            'id': 'api-1',
            'type': 'api',
            'x': 100,
            'y': 0,
            'data': {
              'name': 'Fetch',
              'type': 'http',
              'method': 'GET',
              'url': 'https://example.com',
            },
            'outputs': ['success', 'failure'],
          },
        ],
        'edges': [],
      }),
    );

    await MigrationService().run();

    final migrated =
        jsonDecode(workflows.get('wf-1') as String) as Map<String, dynamic>;
    expect(migrated['schemaVersion'], WorkflowMigrationSchema.currentVersion);
    expect(migrated['groupId'], 'no-workgroup');

    final nodes = migrated['nodes'] as List;
    final apiNode = (nodes.cast<Map>().firstWhere(
          (node) => node['id'] == 'api-1',
        )).cast<String, dynamic>();
    final data = apiNode['data'] as Map;
    expect(data['name'], 'Fetch');
    expect(data['execution'], isA<Map>());
    expect((data['execution'] as Map)['retry'], isA<Map>());
  });

  test('normalizes workflow nodes with missing http fields instead of crashing',
      () async {
    final workflows = await Hive.openBox('workflows_box');
    await workflows.put(
      'wf-malformed-node',
      {
        'id': 'wf-malformed-node',
        'name': 'Malformed Node Workflow',
        'schemaVersion': 1,
        'nodes': [
          {
            'id': 'api-missing-url',
            'type': 'api',
            'x': 12,
            'y': 34,
            'data': {
              'name': 'Broken API',
              'type': 'http',
              'url': null,
              'method': null,
              'headers': {'accept': 'application/json'},
              'execution': {
                'retry': {'maxAttempts': 1}
              },
            },
          },
        ],
        'edges': [],
      },
    );

    await MigrationService().run();

    final migrated = jsonDecode(workflows.get('wf-malformed-node') as String)
        as Map<String, dynamic>;
    final node =
        ((migrated['nodes'] as List).single as Map).cast<String, dynamic>();
    final data = (node['data'] as Map).cast<String, dynamic>();

    expect(data['url'], '');
    expect(data['method'], 'GET');
    expect(data['name'], 'Broken API');
    expect(data['execution'], isA<Map>());
  });
}
