import 'package:hive/hive.dart';

part 'workflow_edge.g.dart';

@HiveType(typeId: 2)
class WorkflowEdge {
  @HiveField(0)
  final String sourceNodeId;

  @HiveField(1)
  final String targetNodeId;

  @HiveField(2)
  final String sourcePort;

  @HiveField(3)
  final String targetPort;
  
  @HiveField(4)
  final String id;

  WorkflowEdge({
    required this.sourceNodeId,
    required this.targetNodeId,
    this.sourcePort = 'output',
    this.targetPort = 'input',
    String? id,
  }) : this.id = id ?? '${sourceNodeId}_${sourcePort}_${targetNodeId}_${targetPort}'; // Simple ID generation

  Map<String, dynamic> toJson() => {
    'id': id,
    'from': sourceNodeId,
    'to': targetNodeId,
    'fromPort': sourcePort,
    'toPort': targetPort,
  };

  factory WorkflowEdge.fromJson(Map<String, dynamic> json) => WorkflowEdge(
    id: json['id'],
    sourceNodeId: json['from'],
    targetNodeId: json['to'],
    sourcePort: json['fromPort'] ?? 'output',
    targetPort: json['toPort'] ?? 'input',
  );
}
