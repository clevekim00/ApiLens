import 'package:flutter/material.dart';
import '../../domain/models/workflow_node.dart';
import '../../domain/models/workflow_edge.dart';

class EdgePainter extends CustomPainter {
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final Offset? dragStart;
  final Offset? dragEnd;

  EdgePainter({
    required this.nodes, 
    required this.edges,
    this.dragStart,
    this.dragEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw existing edges
    for (final edge in edges) {
      final source = nodes.firstWhere((n) => n.id == edge.sourceNodeId, orElse: () => WorkflowNode(id: '', type: '', x: 0, y: 0));
      final target = nodes.firstWhere((n) => n.id == edge.targetNodeId, orElse: () => WorkflowNode(id: '', type: '', x: 0, y: 0));
      
      if (source.id.isNotEmpty && target.id.isNotEmpty) {
        // Simple visual offset for Condition/API nodes
        double sourceOffsetY = 40;
        if (edge.sourcePort == 'true' || edge.sourcePort == 'success') sourceOffsetY = 20; 
        if (edge.sourcePort == 'false' || edge.sourcePort == 'failure') sourceOffsetY = 60;
        
        final start = Offset(source.x + 160, source.y + sourceOffsetY); 
        final end = Offset(target.x, target.y + 40);         
        
        _drawCurvedLine(canvas, start, end, paint);
      }
    }
    
    // Draw temporary drag line
    if (dragStart != null && dragEnd != null) {
      final tempPaint = Paint()
        ..color = Colors.blueAccent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
        
      // canvas.drawLine(dragStart!, dragEnd!, tempPaint);
      _drawCurvedLine(canvas, dragStart!, dragEnd!, tempPaint);
    }
  }
  
  void _drawCurvedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Cubic Bezier for smooth curve
    // Control points: slightly shifted horizontally
    final controlPoint1 = Offset(start.dx + 50, start.dy);
    final controlPoint2 = Offset(end.dx - 50, end.dy);
    
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy, 
      controlPoint2.dx, controlPoint2.dy, 
      end.dx, end.dy
    );
    
    canvas.drawPath(path, paint);
    
    // Draw arrow at end
    // Simple triangle
    // ... skipping complex arrow geometry for now
    canvas.drawCircle(end, 4, Paint()..color = paint.color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Always repaint for drags
}
