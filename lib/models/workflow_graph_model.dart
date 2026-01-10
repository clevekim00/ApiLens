import 'package:flutter/material.dart';

class WorkflowNode {
  final String id;
  final String? requestId; // null for logic nodes like "If"
  final String type; // 'api', 'if', 'start', 'end'
  final Offset position;
  final String label;
  final Map<String, dynamic> config; // Logic configuration (e.g., conditions)

  WorkflowNode({
    required this.id,
    this.requestId,
    this.type = 'api',
    this.position = Offset.zero,
    required this.label,
    this.config = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'type': type,
      'position': {
        'x': position.dx,
        'y': position.dy,
      },
      'label': label,
      'config': config,
    };
  }

  factory WorkflowNode.fromJson(Map<String, dynamic> json) {
    return WorkflowNode(
      id: json['id'],
      requestId: json['requestId'],
      type: json['type'] ?? 'api',
      position: Offset(
        (json['position']['x'] as num).toDouble(),
        (json['position']['y'] as num).toDouble(),
      ),
      label: json['label'],
      config: Map<String, dynamic>.from(json['config'] ?? {}),
    );
  }

  WorkflowNode copyWith({
    Offset? position,
    String? label,
    Map<String, dynamic>? config,
  }) {
    return WorkflowNode(
      id: id,
      requestId: requestId,
      type: type,
      position: position ?? this.position,
      label: label ?? this.label,
      config: config ?? this.config,
    );
  }
}

class WorkflowEdge {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  final String? fromPort; // e.g., 'success', 'failure'
  final Map<String, dynamic> dataMapping; // Mapping logic between nodes

  WorkflowEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.fromPort,
    this.dataMapping = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'fromPort': fromPort,
      'dataMapping': dataMapping,
    };
  }

  factory WorkflowEdge.fromJson(Map<String, dynamic> json) {
    return WorkflowEdge(
      id: json['id'],
      fromNodeId: json['fromNodeId'],
      toNodeId: json['toNodeId'],
      fromPort: json['fromPort'],
      dataMapping: Map<String, dynamic>.from(json['dataMapping'] ?? {}),
    );
  }
}
