import 'package:dio/dio.dart';
import '../../workflow_editor/domain/models/workflow_node.dart';
import '../../workflow_editor/domain/models/workflow_edge.dart';
import '../../workflow_editor/domain/models/node_config.dart';
import '../domain/models/execution_models.dart';
import '../../../core/utils/template_resolver.dart';
import '../../../core/utils/expression_evaluator.dart';
import '../../../core/network/websocket/websocket_manager.dart';
import '../../../core/network/graphql_service.dart';
import '../../../features/graphql/domain/models/graphql_request_config.dart';
import 'dart:async';

class ExecutionEngine {
  final Dio _dio;
  final WebSocketManager? _wsManager;
  final GraphQLService? _gqlService;
  final void Function(String message)? onLog;
  
  // Runtime state for active connections within a workflow run
  // Maps stored sessionKey to underlying connectionId form WSManager
  final Map<String, String> _sessionKeyToConnectionId = {};

  ExecutionEngine({Dio? dio, WebSocketManager? wsManager, GraphQLService? gqlService, this.onLog}) 
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
        final duration = start != null ? DateTime.now().millisecondsSinceEpoch - start : 0;
        onLog?.call('<-- ${response.statusCode} ${response.requestOptions.uri} (${duration}ms)');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        onLog?.call('!!! Error: ${e.message}');
        return handler.next(e);
      },
    ));
  }

  Map<String, dynamic> _buildContext(Map<String, NodeRunResult> results) {
    final context = <String, dynamic>{
      'node': {},
      'env': {}
    };
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

  Stream<NodeRunResult> runWorkflow(List<WorkflowNode> nodes, List<WorkflowEdge> edges) async* {
    final startNode = nodes.firstWhere(
      (n) => n.type == 'start', 
      orElse: () => throw Exception('No Start Node found')
    );

    final results = <String, NodeRunResult>{};
    final visitedPath = <String>{};
    String? currentNodeId = startNode.id;

    while (currentNodeId != null) {
      if (visitedPath.contains(currentNodeId)) {
        yield NodeRunResult(
          nodeId: currentNodeId,
          status: NodeStatus.failure,
          finishedAt: DateTime.now(),
          errorMessage: 'Cycle detected!',
        );
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
      yield result;

      String? targetPort; 
      
      try {
        if (node.type == 'api') {
           final config = node.config as HttpNodeConfig;
           final url = TemplateResolver.resolve(config.url, context);
           onLog?.call('[${node.id}] Requesting: $url');
           
           final response = await _dio.request(
             url,
             options: Options(method: config.method, headers: config.headers),
             data: config.body
           );
           
           result = result.copyWith(
             status: NodeStatus.success,
             statusCode: response.statusCode,
             responseBody: response.data,
             responseHeaders: response.headers.map.map((k, v) => MapEntry(k, v.join(','))),
             finishedAt: DateTime.now(),
           );
           
           if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
             targetPort = 'success';
           } else {
             targetPort = 'failure';
           }
           
        } else if (node.type == 'condition') {
           final config = node.config as ConditionNodeConfig;
           final match = ExpressionEvaluator.evaluate(config.expression, context);
           result = result.copyWith(
             status: NodeStatus.success,
             finishedAt: DateTime.now(),
             responseBody: {'result': match},
           );
           targetPort = match ? 'true' : 'false';
           
        } else if (node.type == 'ws_connect') {
           final config = node.config as WebSocketConnectNodeConfig;
           if (_wsManager == null) throw Exception('WebSocketManager not initialized');
           
           String urlToConnect;
           if (config.mode == 'configRef') {
              if (config.configRefId == 'ws-config-001') {
                 urlToConnect = 'wss://echo.websocket.org/'; 
              } else {
                 urlToConnect = config.url ?? '';
              }
           } else {
              urlToConnect = TemplateResolver.resolve(config.url ?? '', context);
           }
           
           onLog?.call('[${node.id}] WS Connect: $urlToConnect (as "${config.storeAs}")');

           try {
             final cid = await _wsManager!.connect(urlToConnect, headers: config.headers);
             _sessionKeyToConnectionId[config.storeAs] = cid;
             
             result = result.copyWith(status: NodeStatus.success, finishedAt: DateTime.now(), responseBody: {'connectionId': cid});
             targetPort = 'success';
             onLog?.call('[${node.id}] Connected (ID: $cid)');
           } catch (e) {
             onLog?.call('[${node.id}] Connection Failed: $e');
             throw e;
           }

        } else if (node.type == 'ws_send') {
           final config = node.config as WebSocketSendNodeConfig;
           final cid = _sessionKeyToConnectionId[config.sessionKey];
           if (cid == null) throw Exception('No active WS session for key: ${config.sessionKey}');
           
           final payload = TemplateResolver.resolve(config.payload, context);
           onLog?.call('[${node.id}] WS Send (${config.sessionKey}): $payload');
           
           _wsManager!.send(cid, payload);
           
           result = result.copyWith(status: NodeStatus.success, finishedAt: DateTime.now());
           targetPort = 'success';

        } else if (node.type == 'ws_wait') {
           final config = node.config as WebSocketWaitNodeConfig;
           final cid = _sessionKeyToConnectionId[config.sessionKey];
           if (cid == null) throw Exception('No active WS session for key: ${config.sessionKey}');
           
           final matchType = config.match['type'] as String? ?? 'containsText';
           final matchValue = config.match['value'].toString();
           
           onLog?.call('[${node.id}] WS Wait (${config.sessionKey}) for $matchType: "$matchValue"');
           
           final conn = _wsManager!.getConnection(cid);
           if (conn == null) throw Exception('Connection closed');

           try {
             final matchEvent = await conn.stream.firstWhere((event) {
               final str = event.toString();
               if (matchType == 'containsText') return str.contains(matchValue);
               if (matchType == 'anyMessage') return true;
               if (matchType == 'jsonPathEquals') {
                  if (str.contains(matchValue.split('==').last.replaceAll('"', ''))) return true; 
                  return false; 
               }
               return false;
             }).timeout(Duration(milliseconds: config.timeoutMs));
             
             onLog?.call('[${node.id}] Match found: $matchEvent');
             result = result.copyWith(status: NodeStatus.success, finishedAt: DateTime.now(), responseBody: {'message': matchEvent});
             targetPort = 'success'; 
           } catch (e) {
             onLog?.call('[${node.id}] Wait Timeout or Error: $e');
             throw Exception('Timeout waiting for $matchType');
           }

        } else {
           result = result.copyWith(status: NodeStatus.success, finishedAt: DateTime.now());
           targetPort = 'output'; 
        }
        
      } catch (e) {
        result = result.copyWith(
          status: NodeStatus.failure,
          finishedAt: DateTime.now(),
          errorMessage: e.toString(),
        );
        yield result;
        
        if (node.type == 'api' || node.type == 'ws_connect' || node.type == 'ws_send' || node.type == 'ws_wait') {
          targetPort = 'failure';
        } else {
          return;
        }
      }

      yield result;
      results[node.id] = result;

      if (node.type == 'end') break;

      final nextEdge = edges.firstWhere(
        (e) => e.sourceNodeId == node.id && e.sourcePort == targetPort,
        orElse: () => WorkflowEdge(sourceNodeId: '', targetNodeId: '', sourcePort: '', targetPort: '', id: ''),
      );

      if (nextEdge.sourceNodeId.isNotEmpty) {
        currentNodeId = nextEdge.targetNodeId;
      } else {
        currentNodeId = null;
      }
    }
  }
}
