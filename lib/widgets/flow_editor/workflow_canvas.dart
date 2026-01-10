import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../models/workflow_graph_model.dart';
import '../../services/batch_execution_service.dart';
import 'connection_painter.dart';
import 'node_result_dialogs.dart';

class WorkflowCanvas extends StatefulWidget {
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final Function(String, Offset) onNodeMoved;
  final Function(WorkflowNode) onNodeSelected;
  final Function(String) onNodeDeleted;
  final Function(String, String) onAddLogicNode;
  final Function(WorkflowEdge) onEdgeAdded;
  final Function(WorkflowEdge) onEdgeSelected;
  final Function(String, Offset) onAddRequestNode;
  final List<BatchExecutionResult>? results;

  const WorkflowCanvas({
    super.key,
    required this.nodes,
    required this.edges,
    required this.onNodeMoved,
    required this.onNodeSelected,
    required this.onNodeDeleted,
    required this.onAddLogicNode,
    required this.onEdgeAdded,
    required this.onEdgeSelected,
    required this.onAddRequestNode,
    this.results,
  });

  @override
  State<WorkflowCanvas> createState() => _WorkflowCanvasState();
}

class _WorkflowCanvasState extends State<WorkflowCanvas> {
  final TransformationController _transformationController = TransformationController();
  
  // Dragging connection state
  String? _draggingFromNodeId;
  Offset? _connectionCursor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grid background
        Container(
          color: const Color(0xFF0F172A),
        ),
        
        // Canvas
        InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(5000),
          minScale: 0.1,
          maxScale: 2.0,
          child: DragTarget<Map<String, dynamic>>(
            onWillAccept: (data) => data != null && data.containsKey('requestId'),
            onAcceptWithDetails: (details) {
              final localPos = _transformationController.toScene(details.offset);
              widget.onAddRequestNode(details.data['requestId'], localPos);
            },
            builder: (context, candidateData, rejectedData) {
              return SizedBox(
                width: 10000,
                height: 10000,
                child: Stack(
                  children: [
                    // Lines
                    CustomPaint(
                      painter: ConnectionPainter(
                        nodes: widget.nodes,
                        edges: widget.edges,
                        draggingFromNodeId: _draggingFromNodeId,
                        connectionCursor: _connectionCursor,
                      ),
                    ),

                    // Edge Settings Buttons
                    ...widget.edges.map((edge) => _buildEdgeSettings(edge)),

                    // Nodes
                    ...widget.nodes.map((node) => _buildNode(node)),
                  ],
                ),
              );
            },
          ),
        ),

        // Toolbar - Moved to top of stack
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF334155)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolbarButton(
                  icon: Icons.alt_route,
                  label: 'If/Else',
                  onTap: () => widget.onAddLogicNode('if', 'If Condition'),
                ),
                const SizedBox(width: 8),
                _buildToolbarButton(
                  icon: Icons.terminal,
                  label: 'Log',
                  onTap: () => widget.onAddLogicNode('log', 'Log Output'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEdgeSettings(WorkflowEdge edge) {
    final fromNode = widget.nodes.firstWhere((n) => n.id == edge.fromNodeId, orElse: () => WorkflowNode(id: '', label: ''));
    final toNode = widget.nodes.firstWhere((n) => n.id == edge.toNodeId, orElse: () => WorkflowNode(id: '', label: ''));

    if (fromNode.id.isEmpty || toNode.id.isEmpty) return const SizedBox.shrink();

    // Calculate midpoint
    final start = fromNode.position + const Offset(150, 30);
    final end = toNode.position + const Offset(0, 30);
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    return Positioned(
      left: mid.dx - 12,
      top: mid.dy - 12,
      child: GestureDetector(
        onTap: () => widget.onEdgeSelected(edge),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(Icons.settings, size: 16, color: Color(0xFF06B6D4)),
        ),
      ),
    );
  }

  Widget _buildNode(WorkflowNode node) {
    final nodeResult = widget.results?.where((r) => r.nodeId == node.id).lastOrNull;

    return Positioned(
      left: node.position.dx,
      top: node.position.dy,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main node body (placed first so ports can be on top)
          GestureDetector(
            onPanUpdate: (details) {
              widget.onNodeMoved(node.id, node.position + details.delta);
            },
            child: Container(
              width: 180,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getNodeColor(node.type).withOpacity(0.5), 
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getNodeColor(node.type).withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Configurable title area
                      Expanded(
                        child: InkWell(
                          onTap: () => widget.onNodeSelected(node),
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getNodeIcon(node.type),
                                size: 16,
                                color: _getNodeColor(node.type),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  node.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Delete button
                      InkWell(
                        onTap: () => widget.onNodeDeleted(node.id),
                        child: Icon(Icons.close, size: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (node.type == 'api')
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'API Request',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  if (node.type == 'log')
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Log Node',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  
                  // NEW: Result segments
                  if (nodeResult != null) ...[
                    const Divider(color: Color(0xFF334155), height: 16),
                    _buildResultSegment(
                      label: 'Header',
                      onTap: () => _showHeadersModal(nodeResult),
                    ),
                    const Divider(color: Color(0xFF334155), height: 1),
                    _buildResultSegment(
                      label: 'Body',
                      onTap: () => _showBodyModal(nodeResult),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Ports - Placed last so they are on top and correctly handle drag events
          ..._buildPorts(node),
        ],
      ),
    );
  }

  Widget _buildPort(String nodeId, {required bool isInput, String? portId}) {
    return DragTarget<String>(
      onWillAccept: (data) => isInput && data != null && !data.startsWith(nodeId),
      onAccept: (fromNodeIdWithPort) {
        // fromNodeIdWithPort could be "nodeId" or "nodeId:portId"
        final parts = fromNodeIdWithPort.split(':');
        final fromNodeId = parts[0];
        final fromPort = parts.length > 1 ? parts[1] : null;

        widget.onEdgeAdded(WorkflowEdge(
          id: const Uuid().v4(),
          fromNodeId: fromNodeId,
          toNodeId: nodeId,
          fromPort: fromPort,
        ));
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<String>(
          data: portId != null ? '$nodeId:$portId' : nodeId,
          feedback: const SizedBox.shrink(),
          onDragStarted: () {
            if (!isInput) {
              setState(() {
                _draggingFromNodeId = nodeId;
                // We'd ideally track which port is dragging for the ghost line
              });
            }
          },
          onDragUpdate: (details) {
            if (!isInput) {
              setState(() {
                _connectionCursor = _transformationController.toScene(details.globalPosition);
              });
            }
          },
          onDragEnd: (_) {
            setState(() {
              _draggingFromNodeId = null;
              _connectionCursor = null;
            });
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty ? AppTheme.cyanTeal : const Color(0xFF334155),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0F172A), width: 2),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPorts(WorkflowNode node) {
    if (node.type == 'if') {
      return [
        // Input
        Positioned(
          left: -12,
          top: 25 - 4,
          child: _buildPort(node.id, isInput: true),
        ),
        // True Output
        Positioned(
          right: -12,
          top: 15 - 4,
          child: _buildPort(node.id, isInput: false, portId: 'true'),
        ),
        // False Output
        Positioned(
          right: -12,
          top: 40 - 4,
          child: _buildPort(node.id, isInput: false, portId: 'false'),
        ),
        // Labels for True/False
        Positioned(
          right: 12,
          top: 12,
          child: Text('True', style: TextStyle(color: Colors.green[400], fontSize: 9)),
        ),
        Positioned(
          right: 12,
          top: 38,
          child: Text('False', style: TextStyle(color: Colors.red[400], fontSize: 9)),
        ),
      ];
    }

    // Default API / Log node ports
    return [
      Positioned(
        left: -12,
        top: 25 - 4,
        child: _buildPort(node.id, isInput: true),
      ),
      Positioned(
        right: -12,
        top: 25 - 4,
        child: _buildPort(node.id, isInput: false),
      ),
    ];
  }

  Widget _buildToolbarButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF06B6D4)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNodeColor(String? type) {
    switch (type) {
      case 'api':
        return AppTheme.cyanTeal;
      case 'if':
        return Colors.purpleAccent;
      case 'log':
        return Colors.amberAccent;
      case 'start':
        return AppTheme.successGreen;
      case 'end':
        return AppTheme.errorRed;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getNodeIcon(String? type) {
    switch (type) {
      case 'api':
        return Icons.http;
      case 'if':
        return Icons.alt_route;
      case 'log':
        return Icons.terminal;
      case 'start':
        return Icons.play_circle_outline;
      case 'end':
        return Icons.stop_circle_outlined;
      default:
        return Icons.widgets;
    }
  }
}
