import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workflow_editor/domain/models/workflow_model.dart';
import '../../workflow_editor/domain/models/workflow_node.dart';
import '../../workflow_editor/domain/models/workflow_edge.dart';
import '../../workflow_editor/domain/models/node_config.dart';

// Execution Status
enum NodeExecutionStatus { pending, running, success, failure, skipped }

class NodeExecutionResult {
  final String nodeId;
  final NodeExecutionStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final dynamic output;
  final String? error;
  final Map<String, dynamic> logs;

  NodeExecutionResult({
    required this.nodeId,
    required this.status,
    required this.startTime,
    this.endTime,
    this.output,
    this.error,
    this.logs = const {},
  });
}

class WorkflowRunnerService {
  Future<Map<String, NodeExecutionResult>> executeWorkflow(WorkflowModel workflow) async {
    final Map<String, NodeExecutionResult> results = {};
    final Map<String, dynamic> executionContext = {...workflow.variables};
    
    // 1. Find Start Node
    final startNodes = workflow.nodes.where((n) => n.type == 'start').toList();
    if (startNodes.isEmpty) {
      // Log error or return empty
      return results;
    }

    // Queue for traversal
    List<String> queue = [startNodes.first.id];
    Set<String> visited = {};

    while (queue.isNotEmpty) {
      final nodeId = queue.removeAt(0);
      if (visited.contains(nodeId)) continue;
      visited.add(nodeId);

      final node = workflow.nodes.firstWhere((n) => n.id == nodeId);
      
      // Execute Node
      final result = await executeNode(node, executionContext);
      results[nodeId] = result;
      
      // Stop path if failure (unless configured otherwise)
      if (result.status == NodeExecutionStatus.failure) {
        continue; 
      }

      // Determine next nodes
      final nextNodeIds = _getNextNodes(node, workflow.edges, result);
      queue.addAll(nextNodeIds);
    }

    return results;
  }

  Future<NodeExecutionResult> executeNode(WorkflowNode node, Map<String, dynamic> context) async {
     final startTime = DateTime.now();
     // Substitute variables in config
     // simple substitute for now
     
     try {
       // Mock execution for now
       await Future.delayed(const Duration(milliseconds: 500));
       
       if (node.type == 'api') {
          // TODO: Real API Call
          return NodeExecutionResult(
            nodeId: node.id, 
            status: NodeExecutionStatus.success, 
            startTime: startTime,
            endTime: DateTime.now(),
            output: {'statusCode': 200, 'body': '{"ok": true}'}
          );
       }
       
       return NodeExecutionResult(
         nodeId: node.id, 
         status: NodeExecutionStatus.success, 
         startTime: startTime,
         endTime: DateTime.now()
       );

     } catch (e) {
       return NodeExecutionResult(
         nodeId: node.id, 
         status: NodeExecutionStatus.failure, 
         startTime: startTime, 
         endTime: DateTime.now(),
         error: e.toString()
       );
     }
  }

  List<String> _getNextNodes(WorkflowNode currentNode, List<WorkflowEdge> edges, NodeExecutionResult result) {
    // Find edges starting from this node
    final outgoing = edges.where((e) => e.sourceNodeId == currentNode.id);
    
    // Filter based on port if needed (e.g. if logic)
    // For 'if' node, result.output might determine 'true' or 'false' port
    
    return outgoing.map((e) => e.targetNodeId).toList();
  }
}

final workflowRunnerServiceProvider = Provider((ref) => WorkflowRunnerService());
