import 'package:flutter/material.dart';
import '../../domain/models/workflow_node.dart';
import '../../domain/models/workflow_edge.dart';

class EdgePathUtil {
  static Path createEdgePath(WorkflowEdge edge, WorkflowNode source, WorkflowNode target) {
      double sourceOffsetY = 40;
      if (edge.sourcePort == 'true' || edge.sourcePort == 'success') sourceOffsetY = 20; 
      if (edge.sourcePort == 'false' || edge.sourcePort == 'failure') sourceOffsetY = 60;
      
      final start = Offset(source.x + 160, source.y + sourceOffsetY); 
      final end = Offset(target.x, target.y + 40);

      final path = Path();
      path.moveTo(start.dx, start.dy);
      
      final controlPoint1 = Offset(start.dx + 50, start.dy);
      final controlPoint2 = Offset(end.dx - 50, end.dy);
      
      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy, 
        controlPoint2.dx, controlPoint2.dy, 
        end.dx, end.dy
      );
      return path;
  }

  static bool isPointNearPath(Path path, Offset point, {double threshold = 15.0}) {
    final bounds = path.getBounds();
    if (!bounds.inflate(threshold).contains(point)) return false;

    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 5.0) {
        final pos = metric.getTangentForOffset(d)?.position;
        if (pos != null) {
          if ((pos - point).distance <= threshold) return true;
        }
      }
    }
    return false;
  }
}
