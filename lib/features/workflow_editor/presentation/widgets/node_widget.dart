import 'package:flutter/material.dart';
import '../../domain/models/workflow_node.dart';
import '../../domain/models/node_port.dart';
import '../../../../core/ui/tokens/app_tokens.dart';

class NodeWidget extends StatefulWidget {
  final WorkflowNode node;
  final bool isActive;
  final bool isRunning;
  final bool isSuccess;
  final bool hasError;
  final Function(Offset globalPos)? onDragStart;
  final Function(Offset globalPos)? onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback? onTap;
  final VoidCallback? onToggleCompact;
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
    this.onToggleCompact,
    this.onPortTap,
  });

  @override
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.hasError || widget.isRunning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.hasError || widget.isRunning) && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.hasError && !widget.isRunning && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: (details) => widget.onDragStart?.call(details.globalPosition),
      onPanUpdate: (details) => widget.onDragUpdate?.call(details.globalPosition),
      onPanEnd: (_) => widget.onDragEnd.call(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => _buildNodeCard(context),
          ),
          ..._buildPorts(context, widget.node.inputs, isInput: true),
          ..._buildPorts(context, widget.node.outputs, isInput: false),
        ],
      ),
    );
  }

  List<Widget> _buildPorts(BuildContext context, List<NodePort> ports, {required bool isInput}) {
    final nodeHeight = widget.node.isCompact ? 40.0 : 80.0;
    final count = ports.length;
    final widgets = <Widget>[];

    for (int i = 0; i < count; i++) {
      final port = ports[i];
      double top = (nodeHeight / 2) - 5.0;
      if (count > 1) {
        top = (nodeHeight / (count + 1)) * (i + 1) - 5.0;
      }

      widgets.add(
        Positioned(
          left: isInput ? -5 : null,
          right: isInput ? null : -5,
          top: top,
          child: GestureDetector(
            onTapDown: (details) => widget.onPortTap?.call(port.key, details.globalPosition),
            onPanStart: (details) => widget.onPortTap?.call(port.key, details.globalPosition),
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

    if (widget.isActive) {
      borderColor = colorScheme.primary;
      borderWidth = 2;
      shadows = [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 2)];
    } else if (widget.isRunning) {
      borderColor = Colors.amber;
      borderWidth = 2;
      final value = _pulseAnimation.value;
      shadows = [BoxShadow(color: Colors.amber.withValues(alpha: 0.1 + (value * 0.2)), blurRadius: 8, spreadRadius: 1)];
    } else if (widget.isSuccess) {
      borderColor = Colors.green;
      borderWidth = 2;
      shadows = [
        BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1),
        BoxShadow(color: Colors.green.withValues(alpha: 0.1), blurRadius: 16, spreadRadius: 4),
      ];
    } else if (widget.hasError) {
      borderColor = Colors.redAccent;
      borderWidth = 2;
      final value = _pulseAnimation.value;
      shadows = [
        BoxShadow(color: Colors.redAccent.withValues(alpha: 0.2 + (value * 0.3)), blurRadius: 8 + (value * 12), spreadRadius: value * 4),
      ];
    }

    Color nodeColor;
    IconData icon;
    String subtitle = 'Node';
    switch (widget.node.type) {
      case 'start': nodeColor = Colors.green; icon = Icons.play_arrow; subtitle = 'START'; break;
      case 'end': nodeColor = Colors.redAccent; icon = Icons.stop; subtitle = 'END'; break;
      case 'api': nodeColor = Colors.blue; icon = Icons.language; subtitle = 'HTTP Request'; break;
      case 'condition': nodeColor = Colors.orange; icon = Icons.diamond; subtitle = 'Condition'; break;
      case 'gql_request': nodeColor = Colors.pink; icon = Icons.hub; subtitle = 'GraphQL Request'; break;
      case 'ws_connect': nodeColor = Colors.deepPurple; icon = Icons.sync_alt; subtitle = 'WebSocket Connect'; break;
      default: nodeColor = Colors.blueGrey; icon = Icons.device_hub;
    }

    return Container(
      width: 160,
      height: widget.node.isCompact ? 40 : 80,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: nodeColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
            child: Row(
              children: [
                Icon(icon, size: 16, color: nodeColor),
                const SizedBox(width: AppTokens.s2),
                Expanded(
                  child: Text(
                    widget.node.data['name'] ?? widget.node.type.toUpperCase(),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(widget.node.isCompact ? Icons.unfold_more : Icons.unfold_less, size: 14, color: nodeColor.withValues(alpha: 0.6)),
                  onPressed: widget.onToggleCompact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
              ],
            ),
          ),
          if (!widget.node.isCompact)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2, vertical: AppTokens.s1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(subtitle, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    if (widget.isSuccess)
                      const Row(children: [Icon(Icons.check_circle, size: 10, color: Colors.green), SizedBox(width: 4), Text('Success/OK', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold))])
                    else if (widget.hasError)
                      const Row(children: [Icon(Icons.error, size: 10, color: Colors.redAccent), SizedBox(width: 4), Text('Failed', style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold))]),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
