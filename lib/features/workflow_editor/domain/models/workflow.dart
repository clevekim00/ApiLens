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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Workflow({
    required this.id,
    required this.name,
    this.schemaVersion = 1,
    required this.nodes,
    required this.edges,
    this.env = const {},
    this.groupId,
     this.lastModified,
    this.createdAt,
    this.updatedAt,
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
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Workflow.fromJson(Map<String, dynamic> json) {
    return Workflow(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Workflow',
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      nodes: (json['nodes'] as List?)?.map((n) => WorkflowNode.fromJson(n)).toList() ?? [],
      edges: (json['edges'] as List?)?.map((e) => WorkflowEdge.fromJson(e)).toList() ?? [],
      env: json['env'] as Map<String, dynamic>? ?? {},
      groupId: json['groupId'] as String?,
      lastModified: json['lastModified'] != null ? DateTime.tryParse(json['lastModified'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
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
    DateTime? createdAt,
    DateTime? updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
