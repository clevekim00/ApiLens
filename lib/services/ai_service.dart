import 'dart:convert';
import '../models/http_request_model.dart';
import '../models/workflow_graph_model.dart';
import 'package:flutter/material.dart';

class AIService {
  /// Parses AI output into an HttpRequestModel
  static HttpRequestModel? parseRequest(String aiOutput) {
    try {
      // Find JSON block if it's wrapped in markdown
      final jsonStr = _extractJson(aiOutput);
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr);
      return HttpRequestModel(
        name: data['name'] ?? 'AI Generated Request',
        method: data['method'] ?? 'GET',
        url: data['url'] ?? '',
        headers: Map<String, String>.from(data['headers'] ?? {}),
        body: data['body'] ?? '',
        queryParams: Map<String, String>.from(data['queryParams'] ?? {}),
      );
    } catch (e) {
      debugPrint('AI Request Parsing Error: $e');
      return null;
    }
  }

  /// Parses AI output into Workflow nodes and edges
  static Map<String, dynamic>? parseWorkflow(String aiOutput) {
    try {
      final jsonStr = _extractJson(aiOutput);
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr);
      final nodesData = data['nodes'] as List<dynamic>?;
      final edgesData = data['edges'] as List<dynamic>?;

      if (nodesData == null) return null;

      final nodes = nodesData.map((n) => WorkflowNode.fromJson(n)).toList();
      final edges = edgesData?.map((e) => WorkflowEdge.fromJson(e)).toList() ?? [];

      return {
        'nodes': nodes,
        'edges': edges,
      };
    } catch (e) {
      debugPrint('AI Workflow Parsing Error: $e');
      return null;
    }
  }

  static String? _extractJson(String input) {
    if (input.contains('```json')) {
      final startIndex = input.indexOf('```json') + 7;
      final endIndex = input.indexOf('```', startIndex);
      return input.substring(startIndex, endIndex).trim();
    } else if (input.contains('{')) {
      final startIndex = input.indexOf('{');
      final endIndex = input.lastIndexOf('}') + 1;
      return input.substring(startIndex, endIndex).trim();
    }
    return null;
  }

  /// Simulated AI Generation for Testing
  static Future<String> generateSimulatedResponse(String prompt, bool isWorkflow) async {
    await Future.delayed(const Duration(seconds: 2));

    if (isWorkflow) {
      return '''
```json
{
  "nodes": [
    {"id": "node_1", "type": "api", "label": "Login API", "position": {"x": 100, "y": 100}},
    {"id": "node_2", "type": "log", "label": "Log Success", "position": {"x": 400, "y": 100}, "config": {"message": "Login processed!"}}
  ],
  "edges": [
    {"id": "edge_1", "fromNodeId": "node_1", "toNodeId": "node_2", "fromPort": "success"}
  ]
}
```
''';
    } else {
      return '''
```json
{
  "name": "JSONPlaceholder Post 1",
  "method": "GET",
  "url": "https://jsonplaceholder.typicode.com/posts/1",
  "headers": {
    "Accept": "application/json"
  }
}
```
''';
    }
  }

  /// Simulated AI Response Explanation
  static Future<String> explainResponse(String body, {int? statusCode}) async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (statusCode != null && statusCode >= 400) {
      return "The request failed with status $statusCode. This often means the resource was not found or there's an authentication issue. Check your URL and headers.";
    }
    
    return "This response contains structured data. It seems to be a valid JSON object/list representing the requested resources. The AI confirms the data format is consistent.";
  }
}
