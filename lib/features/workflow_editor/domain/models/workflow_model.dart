import 'package:hive/hive.dart';
import 'workflow_node.dart';
import 'workflow_edge.dart';

part 'workflow_model.g.dart';

@HiveType(typeId: 3)
class WorkflowModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? groupId;

  @HiveField(3)
  final List<WorkflowNode> nodes;

  @HiveField(4)
  final List<WorkflowEdge> edges;

  @HiveField(5)
  final DateTime lastSavedAt;
  
  @HiveField(6)
  final Map<String, dynamic> variables;

  WorkflowModel({
    required this.id,
    required this.name,
    this.groupId,
    this.nodes = const [],
    this.edges = const [],
    required this.lastSavedAt,
    this.variables = const {},
  });

  WorkflowModel copyWith({
    String? id,
    String? name,
    String? groupId,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
    DateTime? lastSavedAt,
    Map<String, dynamic>? variables,
  }) {
    return WorkflowModel(
      id: id ?? this.id,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      variables: variables ?? this.variables,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'groupId': groupId,
    'nodes': nodes.map((e) => e.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
    'lastSavedAt': lastSavedAt.toIso8601String(),
    'variables': variables,
  };

  factory WorkflowModel.fromJson(Map<String, dynamic> json) {
    return WorkflowModel(
      id: json['id'],
      name: json['name'],
      groupId: json['groupId'],
      nodes: (json['nodes'] as List?)?.map((e) => WorkflowNode.fromJson(e)).toList() ?? [],
      edges: (json['edges'] as List?)?.map((e) => WorkflowEdge.fromJson(e)).toList() ?? [],
      lastSavedAt: DateTime.parse(json['lastSavedAt']),
      variables: json['variables'] ?? {},
    );
  }
}
