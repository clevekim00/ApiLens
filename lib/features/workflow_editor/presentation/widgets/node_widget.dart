import 'package:flutter/material.dart';
import '../../domain/models/workflow_node.dart';
import '../../domain/models/node_port.dart';

class NodeWidget extends StatelessWidget {
  final WorkflowNode node;
  final bool isActive;
  final bool isRunning;
  final bool isSuccess;
  final bool hasError;
  final Function(DraggableDetails) onDragEnd;
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
    required this.onDragEnd,
    this.onTap,
    this.onPortTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Draggable<String>(
        data: node.id,
        feedback: _buildNodeCard(context, isDragging: true),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: _buildNodeCard(context),
        ),
        onDragEnd: onDragEnd,
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
      
      // Fine tune for visual center (port height 12)
      top -= 6.0;

      widgets.add(
        Positioned(
          left: isInput ? -6 : null,
          right: isInput ? null : -6,
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
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 2),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildNodeCard(BuildContext context, {bool isDragging = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Color borderColor = isDragging ? colorScheme.primary : colorScheme.outline;
    double borderWidth = isDragging ? 2 : 1;
    List<BoxShadow> shadows = [
      if (!isDragging)
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
        width: 160,
        height: 80,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
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
              height: 32,
              decoration: BoxDecoration(
                color: nodeColor.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: nodeColor),
                  const SizedBox(width: 8),
                  Text(
                    node.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
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
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    node.data['name'] ?? 'Node ${node.id}',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
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
