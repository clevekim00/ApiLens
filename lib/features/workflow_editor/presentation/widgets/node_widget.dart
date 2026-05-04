import 'package:flutter/material.dart';
import '../../domain/models/workflow_node.dart';
import '../../domain/models/node_port.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
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
    
    Color borderColor = colorScheme.outlineVariant;
    double borderWidth = 1;
    List<BoxShadow> shadows = [];

    if (isActive) {
      borderColor = colorScheme.primary;
      borderWidth = 2;
      shadows = [
        BoxShadow(color: colorScheme.primary.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 2)
      ];
    } else if (isRunning) {
      borderColor = Colors.amber;
      borderWidth = 2;
    } else if (hasError) {
      borderColor = Colors.redAccent;
      borderWidth = 2;
    }

    Color nodeColor;
    IconData icon;
    String subtitle = 'Node';
    
    switch (node.type) {
      case 'start':
        nodeColor = Colors.green;
        icon = Icons.play_arrow;
        subtitle = 'START';
        break;
      case 'end':
        nodeColor = Colors.redAccent;
        icon = Icons.stop;
        subtitle = 'END';
        break;
      case 'api':
        nodeColor = Colors.blue;
        icon = Icons.language;
        subtitle = 'HTTP Request';
        break;
      case 'condition':
        nodeColor = Colors.orange;
        icon = Icons.diamond;
        subtitle = 'Condition';
        break;
      case 'gql_request':
        nodeColor = Colors.pink;
        icon = Icons.hub;
        subtitle = 'GraphQL Request';
        break;
      case 'ws_connect':
        nodeColor = Colors.deepPurple;
        icon = Icons.sync_alt;
        subtitle = 'WebSocket Connect';
        break;
      default:
        nodeColor = Colors.blueGrey;
        icon = Icons.device_hub;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 160,
        height: 80,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: shadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header / Icon area
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: nodeColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: nodeColor),
                  const SizedBox(width: AppTokens.s2),
                  Expanded(
                    child: Text(
                      node.data['name'] ?? node.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Body / Subtitle
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2, vertical: AppTokens.s1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (isSuccess)
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 10, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Success/OK',
                            style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    else if (hasError)
                      Row(
                        children: [
                          Icon(Icons.error, size: 10, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            'Failed',
                            style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
