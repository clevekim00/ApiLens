import 'package:dio/dio.dart';
import '../../workflow_editor/domain/models/workflow_node.dart';
import '../../workflow_editor/domain/models/workflow_edge.dart';
import '../../workflow_editor/domain/models/node_config.dart';
import '../domain/models/execution_models.dart';
import '../../../core/utils/template_resolver.dart';
import '../../../core/utils/expression_evaluator.dart';
import '../../../core/network/websocket/websocket_manager.dart';
import '../../../core/network/graphql_service.dart';
import 'dart:async';

class ExecutionEngine {
  final Dio _dio;
  final WebSocketManager? _wsManager;
  final GraphQLService? _gqlService;
  final void Function(String message)? onLog;

  // Runtime state for active connections within a workflow run
  // Maps stored sessionKey to underlying connectionId form WSManager
  final Map<String, String> _sessionKeyToConnectionId = {};

  ExecutionEngine(
      {Dio? dio,
      WebSocketManager? wsManager,
      GraphQLService? gqlService,
      this.onLog})
      : _dio = dio ?? Dio(),
        _wsManager = wsManager,
        _gqlService = gqlService {
    _dio.options.validateStatus = (status) => true;
    _dio.options.responseType = ResponseType.plain;

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        onLog?.call('--> ${options.method} ${options.uri}');
        options.extra['start_time'] = DateTime.now().millisecondsSinceEpoch;
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final start = response.requestOptions.extra['start_time'] as int?;
        final duration =
            start != null ? DateTime.now().millisecondsSinceEpoch - start : 0;
        onLog?.call(
            '<-- ${response.statusCode} ${response.requestOptions.uri} (${duration}ms)');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        onLog?.call('!!! Error: ${e.message}');
        return handler.next(e);
      },
    ));
  }

  Map<String, dynamic> _buildContext(Map<String, NodeRunResult> results) {
    final context = <String, dynamic>{'node': {}, 'env': {}};
    for (final entry in results.entries) {
      final nodeId = entry.key;
      final result = entry.value;
      context['node'][nodeId] = {
        'status': result.statusCode,
        'response': {
          'body': result.responseBody,
          'headers': result.responseHeaders,
          'statusCode': result.statusCode,
        },
        'error': result.errorMessage,
      };
    }
    return context;
  }

  Future<_NodeExecutionOutcome> _runWithPolicy({
    required WorkflowNode node,
    required ExecutionPolicy policy,
    required Future<_NodeExecutionOutcome> Function() operation,
    bool Function(_NodeExecutionOutcome outcome)? shouldRetryOutcome,
  }) async {
    final retry = policy.retry;
    final maxAttempts = retry.maxAttempts.clamp(0, 100);

    for (var attempt = 0; attempt <= maxAttempts; attempt++) {
      final attemptNumber = attempt + 1;
      try {
        if (attempt > 0) {
          onLog?.call(
            '[${node.id}] Retry attempt $attemptNumber/${maxAttempts + 1}',
          );
        }

        final operationFuture = operation();
        final outcome = policy.timeoutMs != null && policy.timeoutMs! > 0
            ? await operationFuture.timeout(
                Duration(milliseconds: policy.timeoutMs!),
              )
            : await operationFuture;

        final shouldRetry = shouldRetryOutcome?.call(outcome) ?? false;
        if (shouldRetry && attempt < maxAttempts) {
          await _delayBeforeRetry(node, retry, attemptNumber);
          continue;
        }

        return outcome;
      } on TimeoutException catch (error) {
        if (retry.retryOnTimeout && attempt < maxAttempts) {
          onLog?.call('[${node.id}] Timeout: ${error.message ?? error}');
          await _delayBeforeRetry(node, retry, attemptNumber);
          continue;
        }
        rethrow;
      } catch (error) {
        if (attempt < maxAttempts) {
          onLog?.call('[${node.id}] Attempt $attemptNumber failed: $error');
          await _delayBeforeRetry(node, retry, attemptNumber);
          continue;
        }
        rethrow;
      }
    }

    throw StateError('Retry loop exhausted unexpectedly for node ${node.id}');
  }

  Future<void> _delayBeforeRetry(
    WorkflowNode node,
    RetryPolicy retry,
    int failedAttemptNumber,
  ) async {
    final delayMs = retry.backoffMs.clamp(0, 60000);
    if (delayMs > 0) {
      onLog?.call(
        '[${node.id}] Waiting ${delayMs}ms before retry after attempt $failedAttemptNumber',
      );
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
  }

  Stream<WorkflowExecutionEvent> runWorkflow(
      List<WorkflowNode> nodes, List<WorkflowEdge> edges) async* {
    final startNode = nodes.firstWhere((n) => n.type == 'start',
        orElse: () => throw Exception('No Start Node found'));

    final results = <String, NodeRunResult>{};
    final visitedPath = <String>{};
    String? currentNodeId = startNode.id;

    while (currentNodeId != null) {
      if (visitedPath.contains(currentNodeId)) {
        yield NodeExecutionEvent(NodeRunResult(
          nodeId: currentNodeId,
          status: NodeStatus.failure,
          finishedAt: DateTime.now(),
          errorMessage: 'Cycle detected!',
        ));
        return;
      }
      visitedPath.add(currentNodeId);

      final node = nodes.firstWhere((n) => n.id == currentNodeId);
      final context = _buildContext(results);

      var result = NodeRunResult(
        nodeId: node.id,
        status: NodeStatus.running,
        startedAt: DateTime.now(),
      );
      yield NodeExecutionEvent(result);

      String? targetPort;

      try {
        if (node.type == 'api') {
          final config = node.config as HttpNodeConfig;
          final outcome = await _runWithPolicy(
            node: node,
            policy: config.executionPolicy,
            shouldRetryOutcome: (outcome) {
              final statusCode = outcome.result.statusCode;
              return statusCode != null &&
                  config.executionPolicy.retry.retryOnStatusCodes
                      .contains(statusCode);
            },
            operation: () async {
              final url = TemplateResolver.resolve(config.url, context);
              onLog?.call('[${node.id}] Requesting: $url');

              final response = await _dio.request(
                url,
                options:
                    Options(method: config.method, headers: config.headers),
                data: config.body,
              );

              final nextResult = result.copyWith(
                status: NodeStatus.success,
                statusCode: response.statusCode,
                responseBody: response.data,
                responseHeaders: response.headers.map
                    .map((k, v) => MapEntry(k, v.join(','))),
                finishedAt: DateTime.now(),
              );

              final nextPort = response.statusCode != null &&
                      response.statusCode! >= 200 &&
                      response.statusCode! < 300
                  ? 'success'
                  : 'failure';

              return _NodeExecutionOutcome(nextResult, nextPort);
            },
          );

          result = outcome.result;
          targetPort = outcome.targetPort;
        } else if (node.type == 'condition') {
          final config = node.config as ConditionNodeConfig;
          final match =
              ExpressionEvaluator.evaluate(config.expression, context);
          result = result.copyWith(
            status: NodeStatus.success,
            finishedAt: DateTime.now(),
            responseBody: {'result': match},
          );
          targetPort = match ? 'true' : 'false';
        } else if (node.type == 'ws_connect') {
          final config = node.config as WebSocketConnectNodeConfig;
          if (_wsManager == null) {
            throw Exception('WebSocketManager not initialized');
          }

          final outcome = await _runWithPolicy(
            node: node,
            policy: config.executionPolicy,
            operation: () async {
              String urlToConnect;
              if (config.mode == 'configRef') {
                if (config.configRefId == 'ws-config-001') {
                  urlToConnect = 'wss://echo.websocket.org/';
                } else {
                  urlToConnect = config.url ?? '';
                }
              } else {
                urlToConnect =
                    TemplateResolver.resolve(config.url ?? '', context);
              }

              onLog?.call(
                  '[${node.id}] WS Connect: $urlToConnect (as "${config.storeAs}")');

              try {
                final cid = await _wsManager.connect(
                  urlToConnect,
                  headers: config.headers,
                );
                _sessionKeyToConnectionId[config.storeAs] = cid;

                final nextResult = result.copyWith(
                    status: NodeStatus.success,
                    finishedAt: DateTime.now(),
                    responseBody: {'connectionId': cid});
                onLog?.call('[${node.id}] Connected (ID: $cid)');
                return _NodeExecutionOutcome(nextResult, 'success');
              } catch (e) {
                onLog?.call('[${node.id}] Connection Failed: $e');
                rethrow;
              }
            },
          );

          result = outcome.result;
          targetPort = outcome.targetPort;
        } else if (node.type == 'ws_send') {
          final config = node.config as WebSocketSendNodeConfig;
          final outcome = await _runWithPolicy(
            node: node,
            policy: config.executionPolicy,
            operation: () async {
              final cid = _sessionKeyToConnectionId[config.sessionKey];
              if (cid == null) {
                throw Exception(
                    'No active WS session for key: ${config.sessionKey}');
              }

              final payload = TemplateResolver.resolve(config.payload, context);
              onLog?.call(
                  '[${node.id}] WS Send (${config.sessionKey}): $payload');

              _wsManager!.send(cid, payload);

              return _NodeExecutionOutcome(
                result.copyWith(
                    status: NodeStatus.success, finishedAt: DateTime.now()),
                'success',
              );
            },
          );

          result = outcome.result;
          targetPort = outcome.targetPort;
        } else if (node.type == 'ws_wait') {
          final config = node.config as WebSocketWaitNodeConfig;
          final outcome = await _runWithPolicy(
            node: node,
            policy: config.executionPolicy,
            operation: () async {
              final cid = _sessionKeyToConnectionId[config.sessionKey];
              if (cid == null) {
                throw Exception(
                    'No active WS session for key: ${config.sessionKey}');
              }

              final matchType =
                  config.match['type'] as String? ?? 'containsText';
              final matchValue = config.match['value'].toString();

              onLog?.call(
                  '[${node.id}] WS Wait (${config.sessionKey}) for $matchType: "$matchValue"');

              final conn = _wsManager!.getConnection(cid);
              if (conn == null) {
                throw Exception('Connection closed');
              }

              try {
                final matchEvent = await conn.stream.firstWhere((event) {
                  final str = event.toString();
                  if (matchType == 'containsText') {
                    return str.contains(matchValue);
                  }
                  if (matchType == 'anyMessage') return true;
                  if (matchType == 'jsonPathEquals') {
                    if (str.contains(
                        matchValue.split('==').last.replaceAll('"', ''))) {
                      return true;
                    }
                    return false;
                  }
                  return false;
                });

                onLog?.call('[${node.id}] Match found: $matchEvent');
                return _NodeExecutionOutcome(
                  result.copyWith(
                      status: NodeStatus.success,
                      finishedAt: DateTime.now(),
                      responseBody: {'message': matchEvent}),
                  'success',
                );
              } catch (e) {
                onLog?.call('[${node.id}] Wait Timeout or Error: $e');
                throw Exception('Timeout waiting for $matchType');
              }
            },
          );

          result = outcome.result;
          targetPort = outcome.targetPort;
        } else if (node.type == 'gql_request') {
          final config = node.config as GraphQLNodeConfig;
          if (_gqlService == null) {
            throw Exception('GraphQLService not initialized');
          }

          final outcome = await _runWithPolicy(
            node: node,
            policy: config.executionPolicy,
            shouldRetryOutcome: (outcome) {
              final statusCode = outcome.result.statusCode;
              return statusCode != null &&
                  config.executionPolicy.retry.retryOnStatusCodes
                      .contains(statusCode);
            },
            operation: () async {
              final url = TemplateResolver.resolve(config.url, context);
              final query = TemplateResolver.resolve(config.query, context);

              onLog?.call('[${node.id}] GQL Request to $url');

              try {
                final response = await _gqlService.query(
                  url,
                  query,
                  variables: config.variables.map((k, v) => MapEntry(
                      k, TemplateResolver.resolve(v.toString(), context))),
                  headers: config.headers?.map((k, v) => MapEntry(k,
                          TemplateResolver.resolve(v.toString(), context))) ??
                      {},
                );

                final nextResult = result.copyWith(
                  status: response.isSuccess
                      ? NodeStatus.success
                      : NodeStatus.failure,
                  statusCode: response.statusCode,
                  finishedAt: DateTime.now(),
                  responseBody: {
                    'data': response.data,
                    'errors': response.errors,
                    'statusCode': response.statusCode,
                    'durationMs': response.durationMs,
                  },
                );
                return _NodeExecutionOutcome(
                  nextResult,
                  response.isSuccess ? 'success' : 'failure',
                );
              } catch (e) {
                onLog?.call('[${node.id}] GQL Error: $e');
                rethrow;
              }
            },
          );

          result = outcome.result;
          targetPort = outcome.targetPort;
        } else {
          result = result.copyWith(
              status: NodeStatus.success, finishedAt: DateTime.now());
          targetPort = 'output';
        }
      } catch (e) {
        result = result.copyWith(
          status: NodeStatus.failure,
          finishedAt: DateTime.now(),
          errorMessage: e.toString(),
        );
        yield NodeExecutionEvent(result);

        if (node.type == 'api' ||
            node.type == 'ws_connect' ||
            node.type == 'ws_send' ||
            node.type == 'ws_wait') {
          targetPort = 'failure';
        } else {
          return;
        }
      }

      yield NodeExecutionEvent(result);
      results[node.id] = result;

      if (node.type == 'end') break;

      final nextEdge = edges.firstWhere(
        (e) => e.sourceNodeId == node.id && e.sourcePort == targetPort,
        orElse: () => WorkflowEdge(
            sourceNodeId: '',
            targetNodeId: '',
            sourcePort: '',
            targetPort: '',
            id: ''),
      );

      if (nextEdge.sourceNodeId.isNotEmpty) {
        yield EdgeExecutionEvent(nextEdge.id, isError: targetPort == 'failure');
        currentNodeId = nextEdge.targetNodeId;
      } else {
        currentNodeId = null;
      }
    }
  }
}

class _NodeExecutionOutcome {
  final NodeRunResult result;
  final String? targetPort;

  const _NodeExecutionOutcome(this.result, this.targetPort);
}
