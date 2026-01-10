import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'http_request_model.dart';
import 'workflow_graph_model.dart';

class ApiCollectionModel {
  final String id;
  final String name;
  final String description;
  final List<HttpRequestModel> requests;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isExpanded; // UI state for expandable view
  final bool chainMode; // Enable workflow data passing
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;

  ApiCollectionModel({
    String? id,
    required this.name,
    this.description = '',
    List<HttpRequestModel>? requests,
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.isExpanded = true,
    this.chainMode = false,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
  })  : id = id ?? const Uuid().v4(),
        requests = requests ?? [],
        nodes = nodes ?? [],
        edges = edges ?? [],
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  // Convert to JSON for file export
  Map<String, dynamic> toJson() {
    return {
      'version': '1.0',
      'collection': {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'isExpanded': isExpanded,
        'chainMode': chainMode,
        'requests': requests.map((req) => req.toJson()).toList(),
        'nodes': nodes.map((node) => node.toJson()).toList(),
        'edges': edges.map((edge) => edge.toJson()).toList(),
      },
    };
  }

  // Create from JSON file
  factory ApiCollectionModel.fromJson(Map<String, dynamic> json) {
    final collection = json['collection'] ?? json;
    
    return ApiCollectionModel(
      id: collection['id'],
      name: collection['name'],
      description: collection['description'] ?? '',
      requests: (collection['requests'] as List<dynamic>?)
              ?.map((req) => HttpRequestModel.fromJson(req))
              .toList() ??
          [],
      createdAt: DateTime.parse(collection['createdAt']),
      modifiedAt: DateTime.parse(collection['modifiedAt']),
      isExpanded: collection['isExpanded'] ?? true,
      chainMode: collection['chainMode'] ?? false,
      nodes: (collection['nodes'] as List<dynamic>?)
              ?.map((node) => WorkflowNode.fromJson(node))
              .toList() ??
          [],
      edges: (collection['edges'] as List<dynamic>?)
              ?.map((edge) => WorkflowEdge.fromJson(edge))
              .toList() ??
          [],
    );
  }

  // Convert to JSON string for file
  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  // Create from JSON string
  factory ApiCollectionModel.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    return ApiCollectionModel.fromJson(json);
  }

  // Create a copy with modified fields
  ApiCollectionModel copyWith({
    String? id,
    String? name,
    String? description,
    List<HttpRequestModel>? requests,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isExpanded,
    bool? chainMode,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
  }) {
    return ApiCollectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      requests: requests ?? this.requests,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
      isExpanded: isExpanded ?? this.isExpanded,
      chainMode: chainMode ?? this.chainMode,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }

  // Add request to collection
  ApiCollectionModel addRequest(HttpRequestModel request) {
    final updatedRequests = List<HttpRequestModel>.from(requests)..add(request);
    return copyWith(requests: updatedRequests);
  }

  // Remove request from collection
  ApiCollectionModel removeRequest(String requestId) {
    final updatedRequests = requests.where((req) => req.id != requestId).toList();
    return copyWith(requests: updatedRequests);
  }

  // Update request in collection
  ApiCollectionModel updateRequest(HttpRequestModel updatedRequest) {
    final updatedRequests = requests.map((req) {
      return req.id == updatedRequest.id ? updatedRequest : req;
    }).toList();
    return copyWith(requests: updatedRequests);
  }
}
