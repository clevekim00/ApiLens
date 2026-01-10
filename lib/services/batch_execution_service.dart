import '../models/api_collection_model.dart';
import '../models/http_request_model.dart';
import '../models/http_response_model.dart';
import '../services/http_service.dart';
import '../services/variable_substitution_service.dart';
import '../models/workflow_graph_model.dart';

class BatchExecutionResult {
  final HttpRequestModel request;
  final HttpResponseModel? response;
  final String? error;
  final int iteration;
  final int stepIndex; // Which step in the workflow
  final String? nodeId;

  final String type; // 'api', 'if', 'log'
  final String? logMessage;
  final String? nodeLabel;

  BatchExecutionResult({
    required this.request,
    this.response,
    this.error,
    required this.iteration,
    required this.stepIndex,
    this.type = 'api',
    this.logMessage,
    this.nodeLabel,
    this.nodeId,
  });
}

class BatchExecutionService {
  final HttpService _httpService = HttpService();
  final VariableSubstitutionService _variableService = VariableSubstitutionService();
  bool _isCancelled = false;

  // Execute all requests in a collection
  Future<List<BatchExecutionResult>> executeCollection(
    ApiCollectionModel collection,
    Function(int current, int total, String requestName)? onProgress,
  ) async {
    _isCancelled = false;
    final results = <BatchExecutionResult>[];
    final stepResults = <String, Map<String, dynamic>>{}; // nodeId -> result
    final steps = collection.requests;
    int totalIterations = 0;
    for (var request in steps) {
      totalIterations += request.iterationCount;
    }
    int currentIteration = 0;

    final nodeMap = {for (var n in collection.nodes) n.id: n};
    final outgoingEdges = <String, List<WorkflowEdge>>{};
    for (var edge in collection.edges) {
      outgoingEdges.putIfAbsent(edge.fromNodeId, () => []).add(edge);
    }

    // 2. Identify Entry Nodes (nodes with no incoming edges)
    final incomingCount = <String, int>{for (var n in collection.nodes) n.id: 0};
    for (var edge in collection.edges) {
      incomingCount[edge.toNodeId] = (incomingCount[edge.toNodeId] ?? 0) + 1;
    }
    
    final queue = collection.nodes.where((n) => (incomingCount[n.id] ?? 0) == 0).toList();
    // If no isolated entry nodes, start with all nodes as fallback (legacy compatibility)
    if (queue.isEmpty) queue.addAll(collection.nodes);

    final visitedNodes = <String>{};
    int currentIterationGroup = 0;

    // 3. Graph Traversal Execution
    while (queue.isNotEmpty) {
      if (_isCancelled) break;
      
      final node = queue.removeAt(0);
      if (visitedNodes.contains(node.id)) continue;
      visitedNodes.add(node.id);

      // Execute based on node type
      if (node.type == 'api') {
        final requestIndex = collection.requests.indexWhere((r) => r.id == node.requestId);
        if (requestIndex == -1) continue;
        final request = collection.requests[requestIndex];

        var currentRequest = request;

        // Apply mappings from incoming edges
        final incomingEdges = collection.edges.where((e) => e.toNodeId == node.id);
        for (final edge in incomingEdges) {
          if (stepResults.containsKey(edge.fromNodeId)) {
            currentRequest = _variableService.applyMappings(currentRequest, stepResults[edge.fromNodeId]!, edge.dataMapping);
          }
        }

        // Execute API
        for (int i = 1; i <= currentRequest.iterationCount; i++) {
          if (_isCancelled) break;
          currentIteration++;
          onProgress?.call(currentIteration, totalIterations, currentRequest.name);

          try {
            final response = await _httpService.executeRequest(currentRequest);
            results.add(BatchExecutionResult(
              request: currentRequest,
              response: response,
              iteration: i,
              stepIndex: ++currentIterationGroup,
              nodeId: node.id,
            ));
            if (i == currentRequest.iterationCount) {
              stepResults[node.id] = _variableService.responseToContext(response);
            }
          } catch (e) {
            results.add(BatchExecutionResult(
              request: currentRequest,
              error: e.toString(),
              iteration: i,
              stepIndex: ++currentIterationGroup,
              nodeId: node.id,
            ));
            if (i == currentRequest.iterationCount) {
              stepResults[node.id] = {'response': {'error': e.toString(), 'status': 0}};
            }
          }
        }
      } else if (node.type == 'if') {
        // Evaluate IF condition
        final condition = node.config['condition'] ?? '';
        final context = _variableService.buildContext(stepResults.values.toList());
        final result = _evaluateCondition(condition, context);
        stepResults[node.id] = {'conditionResult': result};
      } else if (node.type == 'log') {
        // Evaluate LOG message
        final messageTemplate = node.label; // Use node label as message template for now
        final context = _variableService.buildContext(stepResults.values.toList());
        final formattedMessage = _variableService.substituteVariables(messageTemplate, context);
        
        results.add(BatchExecutionResult(
          request: collection.requests.first, // Placeholder
          type: 'log',
          logMessage: formattedMessage,
          nodeLabel: node.label,
          nodeId: node.id,
          iteration: 1,
          stepIndex: ++currentIterationGroup,
        ));
        
        stepResults[node.id] = {'log': formattedMessage};
      }

      // 4. Queue next nodes based on edges and logic
      if (outgoingEdges.containsKey(node.id)) {
        for (final edge in outgoingEdges[node.id]!) {
          if (node.type == 'if') {
            final branch = stepResults[node.id]?['conditionResult'] == true ? 'true' : 'false';
            if (edge.fromPort == branch) {
              queue.add(nodeMap[edge.toNodeId]!);
            }
          } else {
            queue.add(nodeMap[edge.toNodeId]!);
          }
        }
      }
    }

    return results;
  }

  // Substitute variables in request using context
  HttpRequestModel _substituteVariablesInRequest(
    HttpRequestModel request,
    Map<String, dynamic> context,
  ) {
    // Substitute in URL
    final url = _variableService.substituteVariables(request.url, context);

    // Substitute in headers
    final headers = <String, String>{};
    request.headers.forEach((key, value) {
      headers[key] = _variableService.substituteVariables(value, context);
    });

    // Substitute in body
    final body = _variableService.substituteVariables(request.body, context);

    // Substitute in query params
    final queryParams = <String, String>{};
    request.queryParams.forEach((key, value) {
      queryParams[key] = _variableService.substituteVariables(value, context);
    });

    return request.copyWith(
      url: url,
      headers: headers,
      body: body,
      queryParams: queryParams,
    );
  }

  // Cancel ongoing batch execution
  void cancel() {
    _isCancelled = true;
  }

  bool _evaluateCondition(String condition, Map<String, dynamic> context) {
    if (condition.isEmpty) return true;
    
    // Very simple evaluator for demo purposes
    // e.g. "response.status == 200"
    try {
      if (condition.contains('==')) {
        final parts = condition.split('==');
        final key = parts[0].trim();
        final expectedValue = parts[1].trim();
        
        final actualValue = _variableService.resolveByPath(context, key);
        return actualValue.toString() == expectedValue;
      }
    } catch (e) {
      print('Condition evaluation error: $e');
    }
    
    return false;
  }

  // Get summary statistics from results
  Map<String, dynamic> getSummary(List<BatchExecutionResult> results) {
    int successCount = 0;
    int errorCount = 0;
    int totalRequests = results.length;
    
    final statusCodes = <int, int>{};

    for (var result in results) {
      if (result.response != null) {
        successCount++;
        final statusCode = result.response!.statusCode;
        statusCodes[statusCode] = (statusCodes[statusCode] ?? 0) + 1;
      } else {
        errorCount++;
      }
    }

    return {
      'total': totalRequests,
      'success': successCount,
      'error': errorCount,
      'statusCodes': statusCodes,
    };
  }
}
