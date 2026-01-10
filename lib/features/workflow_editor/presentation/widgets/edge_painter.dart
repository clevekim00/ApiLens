import 'package:flutter/material.dart';
import '../../domain/models/workflow_node.dart';
import '../../domain/models/workflow_edge.dart';
import 'edge_path_util.dart'; // NEW

class EdgePainter extends CustomPainter {
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final Offset? dragStart;
  final Offset? dragEnd;
  final String? selectedEdgeId; // NEW

  EdgePainter({
    required this.nodes, 
    required this.edges,
    this.dragStart,
    this.dragEnd,
    this.selectedEdgeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final defaultPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final selectedPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 4 // Thicker
      ..style = PaintingStyle.stroke;

    // Draw existing edges
    for (final edge in edges) {
      final source = nodes.firstWhere((n) => n.id == edge.sourceNodeId, orElse: () => WorkflowNode(id: '', type: '', x: 0, y: 0));
      final target = nodes.firstWhere((n) => n.id == edge.targetNodeId, orElse: () => WorkflowNode(id: '', type: '', x: 0, y: 0));
      
      if (source.id.isNotEmpty && target.id.isNotEmpty) {
        final path = EdgePathUtil.createEdgePath(edge, source, target);
        
        final isSelected = edge.id == selectedEdgeId;
        canvas.drawPath(path, isSelected ? selectedPaint : defaultPaint);
        
        // Draw arrow at end (simplified)
        final metrics = path.computeMetrics().toList();
        if (metrics.isNotEmpty) {
           final endPos = metrics.last.getTangentForOffset(metrics.last.length)?.position;
           if (endPos != null) {
              canvas.drawCircle(endPos, 4, Paint()..color = (isSelected ? selectedPaint.color : defaultPaint.color)..style = PaintingStyle.fill);
           }
        }
      }
    }
    
    // Draw temporary drag line
    if (dragStart != null && dragEnd != null) {
      final tempPaint = Paint()
        ..color = Colors.blueAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      final path = Path();
      path.moveTo(dragStart!.dx, dragStart!.dy);
      // Cubic Bezier for smooth curve similar to _createEdgePath logic
      final controlPoint1 = Offset(dragStart!.dx + 50, dragStart!.dy);
      final controlPoint2 = Offset(dragEnd!.dx - 50, dragEnd!.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, dragEnd!.dx, dragEnd!.dy);
      
      canvas.drawPath(path, tempPaint);
    }
  }

  @override
  bool hitTest(Offset position) {
    for (final edge in edges) {
      final source = nodes.firstWhere((n) => n.id == edge.sourceNodeId, orElse: () => WorkflowNode(id: '', type: '', x: 0, y: 0));
      final target = nodes.firstWhere((n) => n.id == edge.targetNodeId, orElse: () => WorkflowNode(id: '', type: '', x: 0, y: 0));
      if (source.id.isEmpty || target.id.isEmpty) continue;

      final path = EdgePathUtil.createEdgePath(edge, source, target);
      if (EdgePathUtil.isPointNearPath(path, position)) {
         return true;
      }
    }
    return false;
  }


  @override
  bool shouldRepaint(covariant EdgePainter oldDelegate) {
    return oldDelegate.nodes != nodes || 
           oldDelegate.edges != edges || 
           oldDelegate.dragStart != dragStart || 
           oldDelegate.dragEnd != dragEnd ||
           oldDelegate.selectedEdgeId != selectedEdgeId;
  }
}
