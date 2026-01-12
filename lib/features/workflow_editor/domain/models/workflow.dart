import 'workflow_node.dart';
import 'workflow_edge.dart';

class Workflow {
  final String id;
  final String name;
  final int schemaVersion;
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final Map<String, dynamic> env; // For environment overrides specific to this workflow
  final String? groupId;
  final DateTime? lastModified;

  Workflow({
    required this.id,
    required this.name,
    this.schemaVersion = 1,
    required this.nodes,
    required this.edges,
    this.env = const {},
    this.groupId,
    this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'schemaVersion': schemaVersion,
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
      'env': env,
      'groupId': groupId,
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory Workflow.fromJson(Map<String, dynamic> json) {
    return Workflow(
      id: json['id'] as String,
      name: json['name'] as String,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      nodes: (json['nodes'] as List).map((n) => WorkflowNode.fromJson(n)).toList(),
      edges: (json['edges'] as List).map((e) => WorkflowEdge.fromJson(e)).toList(),
      env: json['env'] as Map<String, dynamic>? ?? {},
      groupId: json['groupId'] as String?,
      lastModified: json['lastModified'] != null ? DateTime.parse(json['lastModified']) : null,
    );
  }
  
  Workflow copyWith({
    String? id,
    String? name,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
    Map<String, dynamic>? env,
    String? groupId,
    DateTime? lastModified,
  }) {
    return Workflow(
      id: id ?? this.id,
      name: name ?? this.name,
      schemaVersion: schemaVersion,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      env: env ?? this.env,
      groupId: groupId ?? this.groupId,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
