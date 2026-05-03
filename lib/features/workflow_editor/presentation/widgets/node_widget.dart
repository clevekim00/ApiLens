import 'package:flutter/material.dart';
import '../../domain/models/workflow_node.dart';
import '../../domain/models/node_port.dart';

class NodeWidget extends StatelessWidget {
  final WorkflowNode node;
  final bool isActive;
  final bool isRunning;
  final bool isSuccess;
  final bool hasError;
  final Function(Offset globalPos)? onDragStart;
  final Function(Offset globalPos)? onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback? onTap;
  
  // Port Callbacks
  final Function(String portKey, Offset globalPos)? onPortTap;

  const NodeWidget({
    super.key,
    required this.node,
    this.isActive = false,
    this.isRunning = false,
    this.isSuccess = false,
    this.hasError = false,
    this.onDragStart,
    this.onDragUpdate,
    required this.onDragEnd,
    this.onTap,
    this.onPortTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onPanStart: (details) {
         // Notify parent (WorkflowCanvas) to start dragging this node
         // We pass global position so Canvas can map it to World space
         onDragStart?.call(details.globalPosition);     
      },
      onPanUpdate: (details) {
         onDragUpdate?.call(details.globalPosition);
      },
      onPanEnd: (_) {
         onDragEnd.call();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildNodeCard(context),
          
          // Render Input Ports
          ..._buildPorts(context, node.inputs, isInput: true),
            
          // Render Output Ports
          ..._buildPorts(context, node.outputs, isInput: false),
        ],
      ),
    );
  }

  List<Widget> _buildPorts(BuildContext context, List<NodePort> ports, {required bool isInput}) {
    // Distribute ports vertically if multiple, or center if single.
    // For MVP, simplest is standard positions.
    // 1 port: centered.
    // 2 ports: 1/3 and 2/3.
    
    // Node Height is 80 fixed.
    final count = ports.length;
    final widgets = <Widget>[];

    for (int i = 0; i < count; i++) {
      final port = ports[i];
      double top = 40.0; // center default
      
      if (count > 1) {
        final step = 80.0 / (count + 1);
        top = step * (i + 1);
      }
      
      // Fine tune for visual center (port height 10)
      top -= 5.0;

      widgets.add(
        Positioned(
          left: isInput ? -5 : null,
          right: isInput ? null : -5,
          top: top,
          child: GestureDetector(
            onTapDown: (details) {
              onPortTap?.call(port.key, details.globalPosition);
            },
            onPanStart: (details) {
               // Treat drag start as a tap to initiate connection mode
               // This also consumes the gesture, preventing canvas panning/node dragging
               onPortTap?.call(port.key, details.globalPosition);
            },
            onPanUpdate: (_) {}, // Conserve gesture
            child: Tooltip(
              message: port.label,
              child: _buildPortCircle(context, port.key),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildPortCircle(BuildContext context, String key) {
    Color color = Colors.grey;
    if (key == 'true') color = Colors.green;
    if (key == 'false') color = Colors.orange;

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 1.5),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildNodeCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Color borderColor = colorScheme.outline;
    double borderWidth = 1;
    List<BoxShadow> shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
    ];

    if (isActive) {
      borderColor = Colors.blueAccent;
      borderWidth = 3;
      shadows = [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)];
    } else if (isRunning) {
      borderColor = Colors.amber;
      borderWidth = 3;
      shadows = [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)];
    } else if (hasError) {
      borderColor = Colors.redAccent;
      borderWidth = 2;
    } else if (isSuccess) {
      borderColor = Colors.greenAccent;
      borderWidth = 2;
    }

    Color nodeColor;
    IconData icon;
    
    switch (node.type) {
      case 'start':
        nodeColor = Colors.green;
        icon = Icons.play_arrow;
        break;
      case 'end':
        nodeColor = Colors.red;
        icon = Icons.stop;
        break;
      case 'api':
        nodeColor = Colors.blue;
        icon = Icons.api;
        break;
      case 'condition':
        nodeColor = Colors.orange;
        icon = Icons.call_split;
        break;
      default:
        nodeColor = Colors.grey;
        icon = Icons.device_hub;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 140,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: shadows,
        ),
        child: Column(
          children: [
            // Header
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: nodeColor.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(9),
                  topRight: Radius.circular(9),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Icon(icon, size: 12, color: nodeColor),
                  const SizedBox(width: 4),
                  Text(
                    node.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: nodeColor,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Center(
                  child: Text(
                    node.data['name'] ?? 'Node ${node.id}',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
