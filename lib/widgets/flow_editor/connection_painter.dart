import 'package:flutter/material.dart';
import '../../models/workflow_graph_model.dart';

class ConnectionPainter extends CustomPainter {
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final String? draggingFromNodeId;
  final Offset? connectionCursor;

  ConnectionPainter({
    required this.nodes,
    required this.edges,
    this.draggingFromNodeId,
    this.connectionCursor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF06B6D4).withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw existing edges
    for (final edge in edges) {
      final fromNode = nodes.firstWhere((n) => n.id == edge.fromNodeId, orElse: () => WorkflowNode(id: '', label: ''));
      final toNode = nodes.firstWhere((n) => n.id == edge.toNodeId, orElse: () => WorkflowNode(id: '', label: ''));

      if (fromNode.id.isEmpty || toNode.id.isEmpty) continue;

      final start = _getPortOffset(fromNode, isInput: false, portId: edge.fromPort);
      final end = _getPortOffset(toNode, isInput: true);

      _drawBezierLine(canvas, start, end, paint);
    }

    // Draw ghost line while dragging
    if (draggingFromNodeId != null && connectionCursor != null) {
      final fromNode = nodes.firstWhere((n) => n.id == draggingFromNodeId);
      final start = _getPortOffset(fromNode, isInput: false); // Default for ghost line
      
      final ghostPaint = Paint()
        ..color = const Color(0xFF06B6D4).withOpacity(0.3)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
        
      _drawBezierLine(canvas, start, connectionCursor!, ghostPaint);
    }
  }

  Offset _getPortOffset(WorkflowNode node, {required bool isInput, String? portId}) {
    double x = isInput ? 0 : 180; // Match node maxWidth
    double y = 25 + 8; // Default vertical center of port

    if (node.type == 'if') {
      if (isInput) {
        y = 25 + 8;
      } else {
        if (portId == 'true') {
          y = 15 + 8;
        } else if (portId == 'false') {
          y = 40 + 8;
        }
      }
    }
    
    return node.position + Offset(x, y);
  }

  void _drawBezierLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    final controlPoint1 = Offset(start.dx + (end.dx - start.dx) / 2, start.dy);
    final controlPoint2 = Offset(start.dx + (end.dx - start.dx) / 2, end.dy);
    path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, end.dx, end.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return true; // Simplified for dragging performance
  }
}
