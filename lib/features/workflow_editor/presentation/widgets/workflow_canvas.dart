import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _focusNode.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  // Coordinate Conversion
  Offset _screenToWorld(Offset screenPos) {
    final Matrix4 transform = _transformationController.value;
    final double scale = transform.getMaxScaleOnAxis();
    final translationVector = transform.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    
    // world = (screen - translation) / scale
    return (screenPos - translation) / scale;
  }

  void _onNodeDragStart(String nodeId, DragStartDetails details) {
    _draggingNodeId = nodeId;
    
    // Select node
    ref.read(workflowEditorProvider.notifier).selectNode(nodeId);
    
    final worldPointer = _screenToWorld(details.globalPosition);
    final node = ref.read(workflowEditorProvider).nodes.firstWhere((n) => n.id == nodeId);
    final nodePos = Offset(node.x, node.y);
    
    // anchor = worldPointer - nodePos
    _grabOffset = worldPointer - nodePos;
  }

  void _onNodeDragUpdate(DragUpdateDetails details) {
    if (_draggingNodeId == null || _grabOffset == null) return;
    
    final worldPointer = _screenToWorld(details.globalPosition);
    final newNodePos = worldPointer - _grabOffset!;
    
    // Optional: Grid Snap
    // if (RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.shiftLeft)) { ... }
    
    ref.read(workflowEditorProvider.notifier).setNodePosition(_draggingNodeId!, newNodePos.dx, newNodePos.dy);
  }

  void _onNodeDragEnd() {
    _draggingNodeId = null;
    _grabOffset = null;
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
                  constrained: false, // Infinite canvas
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
                          child: GestureDetector(
                            behavior: HitTestBehavior.deferToChild, // Only hit where painter says hit
                            onTapUp: (details) {
                              final edgeId = _findEdgeAt(details.localPosition, nodes, edges);
                              if (edgeId != null) {
                                ref.read(workflowEditorProvider.notifier).selectEdge(edgeId);
                              }
                            },
                            // Consume drag gestures on edges to prevent canvas panning
                            onPanStart: (_) {},
                            onPanUpdate: (_) {},
                            child: CustomPaint(
                              painter: EdgePainter(
                                nodes: nodes, 
                                edges: edges,
                                selectedEdgeId: state.selectedEdgeId,
                              ),
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
                              onDragStart: (d) => _onNodeDragStart(node.id, d),
                              onDragUpdate: _onNodeDragUpdate,
                              onDragEnd: _onNodeDragEnd,
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

  String? _findEdgeAt(Offset position, List<WorkflowNode> nodes, List<WorkflowEdge> edges) {
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
