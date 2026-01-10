import 'package:dio/dio.dart';
import '../../workflow/models/workflow.dart';
import '../../workflow/models/workflow_node.dart';
import '../../workflow/models/workflow_edge.dart';

class WorkflowRunner {
  final Dio dio;
  final Map<String, dynamic> initialContext;
  
  // Execution state
  final Map<String, dynamic> executionContext = {};
  
  // Callbacks
  final Function(String nodeId)? onNodeStart;
  final Function(String nodeId, bool success, String? error)? onNodeComplete;
  
  WorkflowRunner({
    required this.dio,
    this.initialContext = const {},
    this.onNodeStart,
    this.onNodeComplete,
  }) {
    executionContext.addAll(initialContext);
  }

  Future<void> run(Workflow workflow) async {
    // 1. Find Start Node
    final startNode = workflow.nodes.firstWhere(
      (n) => n.type == 'start', 
      orElse: () => throw Exception('No start node found')
    );
    
    // 2. Start traversal
    await _executeNode(startNode, workflow);
  }

  Future<void> _executeNode(WorkflowNode node, Workflow workflow) async {
    print('Executing Node: ${node.id} (${node.type})');
    onNodeStart?.call(node.id);
    
    bool success = true;
    String? error;
    
    // 3. Process Node
    try {
      switch (node.type) {
        case 'start':
          break;
          
        case 'api':
          await _executeApiNode(node);
          break;
          
        case 'condition':
          // TODO: Implement condition
          break;
          
        case 'end':
          print('Workflow Ended');
          onNodeComplete?.call(node.id, true, null);
          return;
      }
    } catch (e) {
      success = false;
      error = e.toString();
      executionContext['node.${node.id}.error'] = error;
    }
    
    onNodeComplete?.call(node.id, success, error);
    
    if (!success) return; // Stop on error?

    // 4. Find Next Node(s)
    final edges = workflow.edges.where((e) => e.sourceNodeId == node.id);
    for (final edge in edges) {
      final nextNode = workflow.nodes.firstWhere((n) => n.id == edge.targetNodeId);
      await _executeNode(nextNode, workflow);
    }
  }

  Future<void> _executeApiNode(WorkflowNode node) async {
    // Resolve variables in node data
    final url = _resolveVariables(node.data['url'] ?? '', executionContext);
    final method = node.data['method'] ?? 'GET';
    final headers = Map<String, dynamic>.from(node.data['headers'] ?? {});
    final body = node.data['body']; // Can be string or map
    
    // Resolve headers
    final resolvedHeaders = <String, dynamic>{};
    headers.forEach((key, value) {
      resolvedHeaders[key] = _resolveVariables(value.toString(), executionContext);
    });

    try {
      final response = await dio.request(
        url,
        data: body, // TODO: Resolve body if string
        options: Options(
          method: method,
          headers: resolvedHeaders,
        ),
      );
      
      // Store result
      executionContext['node.${node.id}.response'] = {
        'statusCode': response.statusCode,
        'data': response.data,
        'headers': response.headers.map,
      };
      
      print('Node ${node.id} Success: ${response.statusCode}');
    } catch (e) {
      print('Node ${node.id} Failed: $e');
      rethrow; // Let main loop handle it
    }
  }

  String _resolveVariables(String input, Map<String, dynamic> context) {
    if (input.isEmpty) return input;
    
    // Regex for {{ variable.path }}
    final regex = RegExp(r'\{\{\s*([\w\.]+)\s*\}\}');
    
    return input.replaceAllMapped(regex, (match) {
      final path = match.group(1);
      if (path == null) return match.group(0)!;
      
      return _getValueFromPath(path, context)?.toString() ?? match.group(0)!;
    });
  }

  dynamic _getValueFromPath(String path, Map<String, dynamic> context) {
    final keys = path.split('.');
    dynamic current = context;
    
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null; 
      }
    }
    return current;
  }
}
