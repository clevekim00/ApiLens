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

class WorkflowCanvas extends ConsumerStatefulWidget {
  const WorkflowCanvas({super.key});

  @override
  ConsumerState<WorkflowCanvas> createState() => _WorkflowCanvasState();
}

class _WorkflowCanvasState extends ConsumerState<WorkflowCanvas> {
  // Dragging state for creating new edges
  // Offset? dragStart; // Deprecated by Port-Click mode
  // Offset? dragEnd;
  
  final GlobalKey _canvasKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(); // For keyboard shortcuts

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch global state from controller
    final state = ref.watch(workflowEditorProvider);
    final runnerState = ref.watch(workflowRunnerProvider); // Watch execution
    
    final nodes = state.nodes;
    final edges = state.edges;
    final connectingNodeId = state.connectingNodeId;
    
    // Calculate cursor position for connecting line (Optional for follow-mouse)
    // For MVP click-click, we might just highlight the source port.
    // Enhanced: We can track mouse movement to draw line to cursor?
    // Let's stick to click-click first, maybe just draw line if we can get mouse pos.
    
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                  final selected = ref.read(workflowEditorProvider).selectedNodeId;
                  if (selected != null) {
                    ref.read(workflowEditorProvider.notifier).deleteNode(selected);
                  }
               }
             }
          },
          child: InteractiveViewer(
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
                    painter: GridPainter(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                  ),
                ),

                // Edges (Behind nodes)
                Positioned.fill(
                  child: CustomPaint(
                    painter: EdgePainter(
                      nodes: nodes, 
                      edges: edges,
                      // We can pass connecting info here if we want to draw temp line
                      // connectingNodeId: connectingNodeId,
                      // connectingPortKey: state.connectingPortKey,
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
                      onDragEnd: (details) {
                         ref.read(workflowEditorProvider.notifier).updateNodePosition(
                             node.id, 
                             details.offset.dx - node.x, // Simplified delta
                             details.offset.dy - node.y 
                         );
                      },
                      onTap: () {
                          ref.read(workflowEditorProvider.notifier).selectNode(node.id);
                      },
                      onPortTap: (portKey, globalPos) {
                          // Quick check:
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
                
                // Visual feedback for connecting mode (Overlay)
                if (connectingNodeId != null)
                   Positioned(
                     left: 10, top: 10,
                     child: Container(
                       padding: const EdgeInsets.all(8),
                       color: Colors.yellowAccent,
                       child: const Text('Connecting... Click target Input Port'),
                     ),
                   ),
              ],
            ),
          ),
        ),
      ),
    ));
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
