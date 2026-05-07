import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:apilens/core/network/graphql_service.dart';
import 'package:apilens/core/network/websocket/websocket_manager.dart';
import 'package:apilens/features/execution/application/execution_engine.dart';
import 'package:apilens/features/execution/domain/models/execution_models.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow_edge.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExecutionEngine.runWorkflow', () {
    test('runs start -> api -> end on success port', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.listen((request) async {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'ok': true}));
        await request.response.close();
      });

      final url = 'http://${server.address.address}:${server.port}/ok';

      final nodes = [
        WorkflowNode(id: 'start', type: 'start', x: 0, y: 0),
        WorkflowNode(
          id: 'api1',
          type: 'api',
          x: 100,
          y: 0,
          data: {
            'type': 'http',
            'url': url,
            'method': 'GET',
            'headers': <String, String>{},
            'body': null,
          },
        ),
        WorkflowNode(id: 'end', type: 'end', x: 200, y: 0),
      ];

      final edges = [
        WorkflowEdge(sourceNodeId: 'start', targetNodeId: 'api1'),
        WorkflowEdge(
          sourceNodeId: 'api1',
          sourcePort: 'success',
          targetNodeId: 'end',
        ),
      ];

      final engine = ExecutionEngine();
      final results = await _collectResults(engine.runWorkflow(nodes, edges));

      expect(results['api1']?.status, NodeStatus.success);
      expect(results['api1']?.statusCode, HttpStatus.ok);
      expect(results['end']?.status, NodeStatus.success);
    });

    test('routes api failures to failure port', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.listen((request) async {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'ok': false}));
        await request.response.close();
      });

      final url = 'http://${server.address.address}:${server.port}/fail';

      final nodes = [
        WorkflowNode(id: 'start', type: 'start', x: 0, y: 0),
        WorkflowNode(
          id: 'api1',
          type: 'api',
          x: 100,
          y: 0,
          data: {
            'type': 'http',
            'url': url,
            'method': 'GET',
            'headers': <String, String>{},
            'body': null,
          },
        ),
        WorkflowNode(id: 'end_ok', type: 'end', x: 200, y: -50),
        WorkflowNode(id: 'end_fail', type: 'end', x: 200, y: 50),
      ];

      final edges = [
        WorkflowEdge(sourceNodeId: 'start', targetNodeId: 'api1'),
        WorkflowEdge(
          sourceNodeId: 'api1',
          sourcePort: 'success',
          targetNodeId: 'end_ok',
        ),
        WorkflowEdge(
          sourceNodeId: 'api1',
          sourcePort: 'failure',
          targetNodeId: 'end_fail',
        ),
      ];

      final engine = ExecutionEngine();
      final results = await _collectResults(engine.runWorkflow(nodes, edges));

      expect(results['api1']?.status, NodeStatus.success);
      expect(results['api1']?.statusCode, HttpStatus.internalServerError);
      expect(results['end_ok'], isNull);
      expect(results['end_fail']?.status, NodeStatus.success);
    });

    test('retries api calls on configured status codes', () async {
      var requestCount = 0;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.listen((request) async {
        requestCount++;
        request.response.headers.contentType = ContentType.json;
        if (requestCount == 1) {
          request.response.statusCode = HttpStatus.internalServerError;
          request.response.write(jsonEncode({'ok': false}));
        } else {
          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({'ok': true}));
        }
        await request.response.close();
      });

      final url = 'http://${server.address.address}:${server.port}/retry';

      final nodes = [
        WorkflowNode(id: 'start', type: 'start', x: 0, y: 0),
        WorkflowNode(
          id: 'api1',
          type: 'api',
          x: 100,
          y: 0,
          data: {
            'type': 'http',
            'url': url,
            'method': 'GET',
            'headers': <String, String>{},
            'body': null,
            'execution': {
              'retry': {
                'maxAttempts': 1,
                'backoffMs': 1,
                'retryOnStatusCodes': [500],
              },
            },
          },
        ),
        WorkflowNode(id: 'end', type: 'end', x: 200, y: 0),
      ];

      final edges = [
        WorkflowEdge(sourceNodeId: 'start', targetNodeId: 'api1'),
        WorkflowEdge(
          sourceNodeId: 'api1',
          sourcePort: 'success',
          targetNodeId: 'end',
        ),
      ];

      final engine = ExecutionEngine();
      final results = await _collectResults(engine.runWorkflow(nodes, edges));

      expect(requestCount, 2);
      expect(results['api1']?.status, NodeStatus.success);
      expect(results['api1']?.statusCode, HttpStatus.ok);
      expect(results['end']?.status, NodeStatus.success);
    });

    test('routes api timeout to failure port after retries are exhausted',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.listen((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({'ok': true}));
        await request.response.close();
      });

      final url = 'http://${server.address.address}:${server.port}/slow';

      final nodes = [
        WorkflowNode(id: 'start', type: 'start', x: 0, y: 0),
        WorkflowNode(
          id: 'api1',
          type: 'api',
          x: 100,
          y: 0,
          data: {
            'type': 'http',
            'url': url,
            'method': 'GET',
            'headers': <String, String>{},
            'body': null,
            'execution': {
              'timeoutMs': 20,
              'retry': {'maxAttempts': 1, 'backoffMs': 1},
            },
          },
        ),
        WorkflowNode(id: 'end_ok', type: 'end', x: 200, y: -50),
        WorkflowNode(id: 'end_fail', type: 'end', x: 200, y: 50),
      ];

      final edges = [
        WorkflowEdge(sourceNodeId: 'start', targetNodeId: 'api1'),
        WorkflowEdge(
          sourceNodeId: 'api1',
          sourcePort: 'success',
          targetNodeId: 'end_ok',
        ),
        WorkflowEdge(
          sourceNodeId: 'api1',
          sourcePort: 'failure',
          targetNodeId: 'end_fail',
        ),
      ];

      final engine = ExecutionEngine();
      final results = await _collectResults(engine.runWorkflow(nodes, edges));

      expect(results['api1']?.status, NodeStatus.failure);
      expect(results['api1']?.errorMessage, contains('TimeoutException'));
      expect(results['end_ok'], isNull);
      expect(results['end_fail']?.status, NodeStatus.success);
    });

    test('evaluates condition ports using prior node results', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.listen((request) async {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'ok': true}));
        await request.response.close();
      });

      final url = 'http://${server.address.address}:${server.port}/ok';

      final nodes = [
        WorkflowNode(id: 'start', type: 'start', x: 0, y: 0),
        WorkflowNode(
          id: 'api1',
          type: 'api',
          x: 100,
          y: 0,
          data: {
            'type': 'http',
            'url': url,
            'method': 'GET',
            'headers': <String, String>{},
            'body': null,
          },
        ),
        WorkflowNode(
          id: 'cond1',
          type: 'condition',
          x: 200,
          y: 0,
          data: {
            'type': 'condition',
            // NOTE: ExpressionEvaluator expects spaces around operator.
            'expression': '{{node.api1.status}} == 200',
          },
        ),
        WorkflowNode(id: 'end_true', type: 'end', x: 300, y: -50),
        WorkflowNode(id: 'end_false', type: 'end', x: 300, y: 50),
      ];

      final edges = [
        WorkflowEdge(sourceNodeId: 'start', targetNodeId: 'api1'),
        WorkflowEdge(
          sourceNodeId: 'api1',
          sourcePort: 'success',
          targetNodeId: 'cond1',
        ),
        WorkflowEdge(
          sourceNodeId: 'cond1',
          sourcePort: 'true',
          targetNodeId: 'end_true',
        ),
        WorkflowEdge(
          sourceNodeId: 'cond1',
          sourcePort: 'false',
          targetNodeId: 'end_false',
        ),
      ];

      final engine = ExecutionEngine();
      final results = await _collectResults(engine.runWorkflow(nodes, edges));

      expect(results['cond1']?.status, NodeStatus.success);
      expect(results['end_true']?.status, NodeStatus.success);
      expect(results['end_false'], isNull);
    });

    test('runs ws_connect/send/wait path and matches messages', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.listen((request) async {
        if (!WebSocketTransformer.isUpgradeRequest(request)) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen((data) {
          final message = data.toString();
          if (message.contains('ping')) {
            socket.add('pong');
          } else {
            socket.add('echo:$message');
          }
        });
      });

      final wsUrl = 'ws://${server.address.address}:${server.port}/ws';

      final nodes = [
        WorkflowNode(id: 'start', type: 'start', x: 0, y: 0),
        WorkflowNode(
          id: 'ws_connect',
          type: 'ws_connect',
          x: 100,
          y: 0,
          data: {
            'type': 'ws_connect',
            'mode': 'direct',
            'url': wsUrl,
            'storeAs': 'mainWs',
            'headers': <String, String>{},
          },
        ),
        WorkflowNode(
          id: 'ws_send',
          type: 'ws_send',
          x: 200,
          y: 0,
          data: {
            'type': 'ws_send',
            'sessionKey': 'mainWs',
            'payloadFormat': 'text',
            'payload': 'ping',
          },
        ),
        WorkflowNode(
          id: 'ws_wait',
          type: 'ws_wait',
          x: 300,
          y: 0,
          data: {
            'type': 'ws_wait',
            'sessionKey': 'mainWs',
            'timeoutMs': 800,
            'match': {'type': 'containsText', 'value': 'pong'},
          },
        ),
        WorkflowNode(id: 'end', type: 'end', x: 400, y: 0),
      ];

      final edges = [
        WorkflowEdge(sourceNodeId: 'start', targetNodeId: 'ws_connect'),
        WorkflowEdge(
          sourceNodeId: 'ws_connect',
          sourcePort: 'success',
          targetNodeId: 'ws_send',
        ),
        WorkflowEdge(
          sourceNodeId: 'ws_send',
          sourcePort: 'success',
          targetNodeId: 'ws_wait',
        ),
        WorkflowEdge(
          sourceNodeId: 'ws_wait',
          sourcePort: 'success',
          targetNodeId: 'end',
        ),
      ];

      final engine = ExecutionEngine(wsManager: WebSocketManager());
      final results = await _collectResults(engine.runWorkflow(nodes, edges));

      expect(results['ws_connect']?.status, NodeStatus.success);
      expect(results['ws_send']?.status, NodeStatus.success);
      expect(results['ws_wait']?.status, NodeStatus.success);
      expect(results['ws_wait']?.responseBody, isA<Map>());
      expect(
        (results['ws_wait']?.responseBody as Map)['message'].toString(),
        contains('pong'),
      );
      expect(results['end']?.status, NodeStatus.success);
    });

    test('runs gql_request and routes based on GraphQL response success',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));

      server.listen((request) async {
        final body = await utf8.decoder.bind(request).join();
        expect(body, contains('"query"'));

        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'data': {'hello': 'world'},
          }),
        );
        await request.response.close();
      });

      final url = 'http://${server.address.address}:${server.port}/graphql';

      final nodes = [
        WorkflowNode(id: 'start', type: 'start', x: 0, y: 0),
        WorkflowNode(
          id: 'gql1',
          type: 'gql_request',
          x: 100,
          y: 0,
          data: {
            'type': 'gql_request',
            'mode': 'direct',
            'endpoint': url,
            'headers': <String, String>{},
            'auth': const {'type': 'none'},
            'query': 'query Hello { hello }',
            'variablesJson': '{"id":"1"}',
            'storeAs': 'gqlResult',
          },
        ),
        WorkflowNode(id: 'end', type: 'end', x: 200, y: 0),
      ];

      final edges = [
        WorkflowEdge(sourceNodeId: 'start', targetNodeId: 'gql1'),
        WorkflowEdge(
          sourceNodeId: 'gql1',
          sourcePort: 'success',
          targetNodeId: 'end',
        ),
      ];

      final engine = ExecutionEngine(gqlService: GraphQLService());
      final results = await _collectResults(engine.runWorkflow(nodes, edges));

      expect(results['gql1']?.status, NodeStatus.success);
      expect(results['gql1']?.responseBody, isA<Map>());
      expect(
        ((results['gql1']?.responseBody as Map)['data'] as Map)['hello'],
        'world',
      );
      expect(results['end']?.status, NodeStatus.success);
    });

    test('detects cycles and emits a failure result', () async {
      final nodes = [
        WorkflowNode(id: 'start', type: 'start', x: 0, y: 0),
        // Use an unrecognized node type so the engine uses the default 'output'
        // port without performing any network I/O.
        WorkflowNode(id: 'a', type: 'noop', x: 100, y: 0),
      ];
      final edges = [
        WorkflowEdge(sourceNodeId: 'start', targetNodeId: 'a'),
        WorkflowEdge(
            sourceNodeId: 'a', targetNodeId: 'a', sourcePort: 'output'),
      ];

      final engine = ExecutionEngine();
      final events = await engine.runWorkflow(nodes, edges).toList();
      final failures = events.whereType<NodeExecutionEvent>().where((e) {
        return e.result.status == NodeStatus.failure;
      }).toList();

      expect(failures, isNotEmpty);
      expect(failures.last.result.errorMessage, contains('Cycle'));
    });
  });
}

Future<Map<String, NodeRunResult>> _collectResults(
  Stream<WorkflowExecutionEvent> stream,
) async {
  final results = <String, NodeRunResult>{};
  await for (final event in stream) {
    if (event is NodeExecutionEvent) {
      // Keep the last event per node id (running -> success/failure).
      results[event.result.nodeId] = event.result;
    }
  }
  // Filter out "running" events if a terminal status exists.
  return results;
}
