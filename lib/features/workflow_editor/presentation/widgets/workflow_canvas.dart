import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/workflow_node.dart';
import '../../domain/models/workflow_edge.dart';
import '../../application/workflow_editor_controller.dart';
import '../../../execution/application/workflow_runner_controller.dart';
import '../../../execution/domain/models/execution_models.dart';
import 'node_widget.dart';
import 'edge_painter.dart';
import 'edge_path_util.dart'; // NEW

class WorkflowCanvas extends ConsumerStatefulWidget {
  const WorkflowCanvas({super.key});

  @override
  ConsumerState<WorkflowCanvas> createState() => _WorkflowCanvasState();
}

class _WorkflowCanvasState extends ConsumerState<WorkflowCanvas> {
  // Dragging state
  String? _draggingNodeId;
  Offset? _grabOffset; // In World Coordinates
  
  final GlobalKey _canvasKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(); 
  bool _panEnabled = true; 
  
  final TransformationController _transformationController = TransformationController();
  
  // Drag State
  String? _dragNodeId;
  Offset _grabOffset = Offset.zero;

  @override
  void dispose() {
    _focusNode.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  // Coordinate Conversion
  Offset _toWorld(Offset globalPos) {
    // 1. Convert Global to Local (Consumer's Box relative)
    // Actually, InteractiveViewer's coordinate system is complex.
    // The easiest way is to use the inverse of the transformation matrix.
    // BUT globalPos is Screen coordinates. 
    // We need to convert Screen -> Widget Local -> World Transformed.
    
    // Step 1: Get render box of the Canvas container (the one holding InteractiveViewer or the Stack?)
    // The gesture detector returns global position.
    // If we assume the top-left of the InteractiveViewer is at (0,0) of the viewport...
    // simpler is to map the point to the RenderBox of the InteractiveViewer (or its child).
    
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return globalPos;
    
    final localPos = box.globalToLocal(globalPos);
    
    // Step 2: Apply inverse transformation matrix to get World Coordinates
    final matrix = _transformationController.value;
    final inverse = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
    
    final point = inverse.transform3(Vector3(localPos.dx, localPos.dy, 0));
    return Offset(point.x, point.y);
  }

  @override
  Widget build(BuildContext context) {
    // Watch global state from controller
    final state = ref.watch(workflowEditorProvider);
    final runnerState = ref.watch(workflowRunnerProvider); // Watch execution
    
    final nodes = state.nodes;
    final edges = state.edges;
    final connectingNodeId = state.connectingNodeId;
    
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                 // Click on canvas background
                 ref.read(workflowEditorProvider.notifier).selectNode(null);
                 _focusNode.requestFocus();
              },
              child: KeyboardListener(
                focusNode: _focusNode,
                onKeyEvent: (event) {
                   if (event is KeyDownEvent) {
                     if (event.logicalKey == LogicalKeyboardKey.delete || event.logicalKey == LogicalKeyboardKey.backspace) {
                        final selectedNode = ref.read(workflowEditorProvider).selectedNodeId;
                        final selectedEdge = ref.read(workflowEditorProvider).selectedEdgeId;
                        
                        if (selectedNode != null) {
                          ref.read(workflowEditorProvider.notifier).deleteNode(selectedNode);
                        } else if (selectedEdge != null) {
                          ref.read(workflowEditorProvider.notifier).deleteEdge(selectedEdge);
                        }
                     }
                   }
                },
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: 0.1,
                  maxScale: 2.0,
                  panEnabled: _panEnabled, // Controlled by listener
                  constrained: false, // Infinite canvas
              child: Listener(
                onPointerDown: (event) {
                  // Hit test for edge
                  // Local position in the 5000x5000 canvas
                  final localPos = event.localPosition;
                  final edgeId = _findEdgeAt(localPos, nodes, edges);
                  
                  if (edgeId != null) {
                     // Hit Edge -> Select & Disable Pan
                     ref.read(workflowEditorProvider.notifier).selectEdge(edgeId);
                     setState(() {
                       _panEnabled = false;
                     });
                  } else {
                     // Hit Empty -> Enable Pan (if not hitting node)
                     // Node selection handled by NodeWidget's GestureDetector usually.
                     // But if we clicked background, we might want to deselect?
                     // Existing onTap handles background deselect.
                     setState(() {
                       _panEnabled = true;
                     });
                  }
                },
                onPointerUp: (_) {
                   setState(() => _panEnabled = true);
                },
                onPointerCancel: (_) {
                   setState(() => _panEnabled = true);
                },
                child: SizedBox(
                    width: 5000,
                    height: 5000,
                    child: Stack(
                      key: _canvasKey,
                      children: [
                        // Grid Pattern
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GridPainter(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                          ),
                        ),

                        // Edges (Behind nodes)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: EdgePainter(
                              nodes: nodes, 
                              edges: edges,
                              selectedEdgeId: state.selectedEdgeId,
                            ),
                          ),
                        ),
                        
                        // Nodes
                        ...nodes.map((node) {
                          final execResult = runnerState.results[node.id];
                          final isRunning = execResult?.status == NodeStatus.running;
                          final isSuccess = execResult?.status == NodeStatus.success;
                          final isFailure = execResult?.status == NodeStatus.failure;

                          return Positioned(
                            left: node.x,
                            top: node.y,
                  child: NodeWidget(
                    node: node,
                    isActive: state.selectedNodeId == node.id,
                    isRunning: isRunning,
                    isSuccess: isSuccess,
                    hasError: isFailure,
                    onDragStart: (globalPos) {
                       final worldPos = _toWorld(globalPos);
                       _dragNodeId = node.id;
                       _grabOffset = worldPos - Offset(node.x, node.y);
                       setState(() => _panEnabled = false); // Disable pan when dragging node
                    },
                    onDragUpdate: (globalPos) {
                       if (_dragNodeId != node.id) return;
                       final worldPos = _toWorld(globalPos);
                       final newPos = worldPos - _grabOffset;
                       
                       // Optional Grid Snap (Shift Key not implemented yet, using default free move)
                       ref.read(workflowEditorProvider.notifier).setNodePosition(node.id, newPos.dx, newPos.dy);
                    },
                    onDragEnd: () {
                       _dragNodeId = null;
                       _grabOffset = Offset.zero;
                       setState(() => _panEnabled = true);
                    },
                    onTap: () {
                        ref.read(workflowEditorProvider.notifier).selectNode(node.id);
                    },
                    onPortTap: (portKey, globalPos) {
                        final isInput = node.inputPortKeys.contains(portKey);
                        
                        if (isInput) {
                           ref.read(workflowEditorProvider.notifier).completeConnection(node.id, portKey);
                        } else {
                           ref.read(workflowEditorProvider.notifier).startConnection(node.id, portKey);
                        }
                    }
                  ),
                          );
                        }),
                      ],
                    ),
                  ),
              ),
                ),
              ),
            ),
          ),
          
          // Fixed Connection Feedback Overlay (Outside InteractiveViewer)
          if (connectingNodeId != null)
             Positioned(
               top: 24,
               left: 0,
               right: 0,
               child: Center(
                 child: Material(
                   elevation: 8,
                   borderRadius: BorderRadius.circular(24),
                   color: Colors.blue.shade700,
                   child: Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         SizedBox(
                           width: 16, height: 16, 
                           child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withValues(alpha: 0.8))
                         ),
                         const SizedBox(width: 12),
                         const Text(
                           'Connection Mode: Click a target Input Port to finish',
                           style: TextStyle(
                             color: Colors.white, 
                             fontWeight: FontWeight.bold,
                             fontSize: 15,
                           ),
                         ),
                         const SizedBox(width: 8),
                         IconButton(
                           icon: const Icon(Icons.close, color: Colors.white, size: 18),
                           onPressed: () => ref.read(workflowEditorProvider.notifier).cancelConnection(),
                           tooltip: 'Cancel Connection',
                           padding: EdgeInsets.zero,
                           constraints: const BoxConstraints(),
                         )
                       ],
                     ),
                   ),
                 ),
               ),
             ),
        ],
      ),
    );
  }

  Offset _toWorld(Offset globalPos) {
    // 1. Convert Global to Local (Consumer's Box relative)
    // Actually, InteractiveViewer's coordinate system is complex.
    // The easiest way is to use the inverse of the transformation matrix.
    // BUT globalPos is Screen coordinates. 
    // We need to convert Screen -> Widget Local -> World Transformed.
    
    // Step 1: Get render box of the Canvas container (the one holding InteractiveViewer or the Stack?)
    // The gesture detector returns global position.
    // If we assume the top-left of the InteractiveViewer is at (0,0) of the viewport...
    // simpler is to map the point to the RenderBox of the InteractiveViewer (or its child).
    
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return globalPos;
    
    final localPos = box.globalToLocal(globalPos);
    
    // Step 2: Apply inverse transformation matrix to get World Coordinates
    final matrix = _transformationController.value;
    final inverse = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
    
    final point = inverse.transform3(Vector3(localPos.dx, localPos.dy, 0));
    return Offset(point.x, point.y);
  }

  String? _findEdgeAt(Offset position, List<WorkflowNode> nodes, List<WorkflowEdge> edges) {
    // 1. Check if point is inside any node (Approximate size 150x80 to prevent edge selection under node)
    // This prioritizes Node selection over Edge selection
    for (final node in nodes) {
      final rect = Rect.fromLTWH(node.x, node.y, 150, 80); 
      if (rect.contains(position)) return null; 
    }

    for (final edge in edges) {
      final source = nodes.firstWhere((n) => n.id == edge.sourceNodeId, orElse: () => WorkflowNode(id: '', type: '', x: 0, y: 0));
      final target = nodes.firstWhere((n) => n.id == edge.targetNodeId, orElse: () => WorkflowNode(id: '', type: '', x: 0, y: 0));
      if (source.id.isEmpty || target.id.isEmpty) continue;

      final path = EdgePathUtil.createEdgePath(edge, source, target);
      if (EdgePathUtil.isPointNearPath(path, position)) {
         return edge.id;
      }
    }
    return null;
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const step = 40.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
