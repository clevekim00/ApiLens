import 'package:dio/dio.dart';
import '../../workflow_editor/domain/models/workflow_node.dart';
import '../../workflow_editor/domain/models/workflow_edge.dart'; // Adjust path if needed
import '../../workflow_editor/domain/models/node_config.dart';
import '../domain/models/execution_models.dart';
import '../../../core/utils/template_resolver.dart';
import '../../../core/utils/expression_evaluator.dart';

class ExecutionEngine {
  final Dio _dio;

  ExecutionEngine({Dio? dio}) : _dio = dio ?? Dio();

  // Helper to build context from run results
  Map<String, dynamic> _buildContext(Map<String, NodeRunResult> results) {
    final context = <String, dynamic>{
      'node': {},
      'env': {
        'baseUrl': 'https://api.example.com' // Mock env for now, inject real later
      }
    };
    
    // Populate node results
    for (final entry in results.entries) {
      final nodeId = entry.key; // This should ideally be node NAME for user friendliness, but ID for unique. 
      // User requirement examples: {{node.<nodeName>.response...}}
      // For MVP we map ID. 
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

  /// Executes the workflow and yields updates for each node step.
  Stream<NodeRunResult> runWorkflow(List<WorkflowNode> nodes, List<WorkflowEdge> edges) async* {
    // 1. Find Start Node
    final startNode = nodes.firstWhere(
      (n) => n.type == 'start', 
      orElse: () => throw Exception('No Start Node found')
    );

    // Stored results
    final results = <String, NodeRunResult>{};
    
    // Cycle detection
    final visitedPath = <String>{};
    
    String? currentNodeId = startNode.id;

    while (currentNodeId != null) {
      // Cycle Check (DAG enforcement)
      if (visitedPath.contains(currentNodeId)) {
        yield NodeRunResult(
          nodeId: currentNodeId,
          status: NodeStatus.failure,
          finishedAt: DateTime.now(),
          errorMessage: 'Cycle detected! Execution stopped to prevent infinite loop.',
        );
        return;
      }
      visitedPath.add(currentNodeId);
      
      final node = nodes.firstWhere((n) => n.id == currentNodeId);
      final context = _buildContext(results);
      
      // -- Yield START --
      var result = NodeRunResult(
        nodeId: node.id,
        status: NodeStatus.running,
        startedAt: DateTime.now(),
      );
      yield result;

      // -- EXECUTE --
      String? targetPort; // Determine which port to exit from
      
      try {
        if (node.type == 'api') {
           final config = node.config as HttpNodeConfig;
           // Resolve Templates
           final url = TemplateResolver.resolve(config.url, context);
           // Headers / Body resolution TODO
           
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
           
           // API Routing
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
             responseBody: {'result': match}, // Store result
           );
           targetPort = match ? 'true' : 'false';
           
        } else {
           // Start / End / Others
           result = result.copyWith(status: NodeStatus.success, finishedAt: DateTime.now());
           targetPort = 'output'; // Default
        }
        
      } catch (e) {
        result = result.copyWith(
          status: NodeStatus.failure,
          finishedAt: DateTime.now(),
          errorMessage: e.toString(),
        );
        yield result;
        
        // If API failure, try 'failure' port?
        if (node.type == 'api') {
          targetPort = 'failure';
        } else {
          return; // Stop on unexpected error
        }
      }

      // -- Yield FINISH --
      yield result;
      results[node.id] = result;

      // -- TRAVERSE --
      if (node.type == 'end') {
        currentNodeId = null; 
        break;
      }

      // Find edge matching sourceNode + sourcePort
      // Note: WorkflowEdge doesn't store sourcePort in V1 but we refactored it in Session 2.
      // Let's verify WorkflowEdge model. It HAS sourcePort.
      
      final nextEdge = edges.firstWhere(
        (e) => e.sourceNodeId == node.id && e.sourcePort == targetPort,
        orElse: () => WorkflowEdge(sourceNodeId: '', targetNodeId: '', sourcePort: '', targetPort: '', id: ''),
      );

      if (nextEdge.sourceNodeId.isNotEmpty) {
        currentNodeId = nextEdge.targetNodeId;
      } else {
        currentNodeId = null; // No connection for that result
      }
    }
  }

  Future<NodeRunResult> _executeNode(WorkflowNode node) async {
      // Deprecated internal method, logic moved to main loop for accessing context/routing
      return NodeRunResult(nodeId: node.id);
  }
}
