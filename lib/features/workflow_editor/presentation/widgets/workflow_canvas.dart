import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
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
  static const Size _canvasSize = Size(5000, 5000);
  static const Size _nodeSize = Size(160, 80);
  static const double _minScale = 0.1;
  static const double _maxScale = 2.0;

  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _viewportKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  bool _panEnabled = true;

  final TransformationController _transformationController =
      TransformationController();

  // Drag State
  String? _dragNodeId;
  Offset _grabOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onViewportChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onViewportChanged);
    _focusNode.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onViewportChanged() {
    if (mounted) setState(() {});
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

    return MatrixUtils.transformPoint(inverse, localPos);
  }

  void _addDroppedNode(Map<String, String> payload, Offset globalOffset) {
    final type = payload['type'];
    final label = payload['label'];
    if (type == null || label == null) return;

    final worldPosition = _toWorld(globalOffset);
    ref.read(workflowEditorProvider.notifier).addNode(
          WorkflowNode(
            id: const Uuid().v4(),
            type: type,
            x: worldPosition.dx - 70,
            y: worldPosition.dy - 32,
            data: {'name': label},
          ),
        );
  }

  Size get _viewportSize {
    final renderObject =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    return renderObject?.size ?? Size.zero;
  }

  double get _currentScale {
    return _transformationController.value.getMaxScaleOnAxis();
  }

  void _zoomBy(double factor) {
    final viewport = _viewportSize;
    if (viewport == Size.zero) return;

    final currentScale = _currentScale;
    final nextScale =
        (currentScale * factor).clamp(_minScale, _maxScale).toDouble();
    final focalPoint = Offset(viewport.width / 2, viewport.height / 2);
    final scenePoint = _transformationController.toScene(focalPoint);

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(
        focalPoint.dx - scenePoint.dx * nextScale,
        focalPoint.dy - scenePoint.dy * nextScale,
        0,
        1,
      )
      ..scaleByDouble(nextScale, nextScale, 1, 1);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _fitToNodes(List<WorkflowNode> nodes) {
    final viewport = _viewportSize;
    if (viewport == Size.zero) return;

    if (nodes.isEmpty) {
      _resetZoom();
      return;
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final node in nodes) {
      minX = minX < node.x ? minX : node.x;
      minY = minY < node.y ? minY : node.y;
      maxX = maxX > node.x + _nodeSize.width ? maxX : node.x + _nodeSize.width;
      maxY =
          maxY > node.y + _nodeSize.height ? maxY : node.y + _nodeSize.height;
    }

    final bounds = Rect.fromLTRB(minX, minY, maxX, maxY).inflate(140);
    final scaleX = viewport.width / bounds.width;
    final scaleY = viewport.height / bounds.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY)
        .clamp(_minScale, _maxScale)
        .toDouble();
    final viewportCenter = Offset(viewport.width / 2, viewport.height / 2);
    final boundsCenter = bounds.center;

    _transformationController.value = Matrix4.identity()
      ..translateByDouble(
        viewportCenter.dx - boundsCenter.dx * scale,
        viewportCenter.dy - boundsCenter.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    // Watch global state from controller
    final state = ref.watch(workflowEditorProvider);
    final runnerState = ref.watch(workflowRunnerProvider); // Watch execution

    final nodes = state.nodes;
    final edges = state.edges;
    final connectingNodeId = state.connectingNodeId;

    return DragTarget<Map<String, String>>(
      onAcceptWithDetails: (details) =>
          _addDroppedNode(details.data, details.offset),
      builder: (context, candidateData, rejectedData) {
        return Container(
          key: _viewportKey,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
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
                        if (event.logicalKey == LogicalKeyboardKey.delete ||
                            event.logicalKey == LogicalKeyboardKey.backspace) {
                          final selectedNode =
                              ref.read(workflowEditorProvider).selectedNodeId;
                          final selectedEdge =
                              ref.read(workflowEditorProvider).selectedEdgeId;

                          if (selectedNode != null) {
                            ref
                                .read(workflowEditorProvider.notifier)
                                .deleteNode(selectedNode);
                          } else if (selectedEdge != null) {
                            ref
                                .read(workflowEditorProvider.notifier)
                                .deleteEdge(selectedEdge);
                          }
                        }
                      }
                    },
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      minScale: _minScale,
                      maxScale: _maxScale,
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
                            ref
                                .read(workflowEditorProvider.notifier)
                                .selectEdge(edgeId);
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
                          width: _canvasSize.width,
                          height: _canvasSize.height,
                          child: Stack(
                            key: _canvasKey,
                            children: [
                              // Grid Pattern
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: GridPainter(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withValues(alpha: 0.2)),
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
                                final isRunning =
                                    execResult?.status == NodeStatus.running;
                                final isSuccess =
                                    execResult?.status == NodeStatus.success;
                                final isFailure =
                                    execResult?.status == NodeStatus.failure;

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
                                        _grabOffset =
                                            worldPos - Offset(node.x, node.y);
                                        setState(() => _panEnabled =
                                            false); // Disable pan when dragging node
                                      },
                                      onDragUpdate: (globalPos) {
                                        if (_dragNodeId != node.id) return;
                                        final worldPos = _toWorld(globalPos);
                                        final newPos = worldPos - _grabOffset;

                                        // Optional Grid Snap (Shift Key not implemented yet, using default free move)
                                        ref
                                            .read(
                                                workflowEditorProvider.notifier)
                                            .setNodePosition(
                                                node.id, newPos.dx, newPos.dy);
                                      },
                                      onDragEnd: () {
                                        _dragNodeId = null;
                                        _grabOffset = Offset.zero;
                                        setState(() => _panEnabled = true);
                                      },
                                      onTap: () {
                                        ref
                                            .read(
                                                workflowEditorProvider.notifier)
                                            .selectNode(node.id);
                                      },
                                      onPortTap: (portKey, globalPos) {
                                        final isInput = node.inputPortKeys
                                            .contains(portKey);

                                        if (isInput) {
                                          ref
                                              .read(workflowEditorProvider
                                                  .notifier)
                                              .completeConnection(
                                                  node.id, portKey);
                                        } else {
                                          ref
                                              .read(workflowEditorProvider
                                                  .notifier)
                                              .startConnection(
                                                  node.id, portKey);
                                        }
                                      }),
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
              Positioned(
                top: AppTokens.s3,
                right: AppTokens.s3,
                child: _CanvasControls(
                  scale: _currentScale,
                  onZoomIn: () => _zoomBy(1.2),
                  onZoomOut: () => _zoomBy(1 / 1.2),
                  onFit: () => _fitToNodes(nodes),
                  onReset: _resetZoom,
                ),
              ),
              Positioned(
                right: AppTokens.s3,
                bottom: AppTokens.s3,
                child: _CanvasMiniMap(
                  nodes: nodes,
                  edges: edges,
                  transform: _transformationController.value,
                  viewportSize: _viewportSize,
                  canvasSize: _canvasSize,
                  nodeSize: _nodeSize,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Colors.white.withValues(alpha: 0.8))),
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
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                              onPressed: () => ref
                                  .read(workflowEditorProvider.notifier)
                                  .cancelConnection(),
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
      },
    );
  }

  String? _findEdgeAt(
      Offset position, List<WorkflowNode> nodes, List<WorkflowEdge> edges) {
    // 1. Check if point is inside any node (Approximate size 150x80 to prevent edge selection under node)
    // This prioritizes Node selection over Edge selection
    for (final node in nodes) {
      final rect = Rect.fromLTWH(node.x, node.y, 150, 80);
      if (rect.contains(position)) return null;
    }

    for (final edge in edges) {
      final source = nodes.firstWhere((n) => n.id == edge.sourceNodeId,
          orElse: () => WorkflowNode(id: '', type: '', x: 0, y: 0));
      final target = nodes.firstWhere((n) => n.id == edge.targetNodeId,
          orElse: () => WorkflowNode(id: '', type: '', x: 0, y: 0));
      if (source.id.isEmpty || target.id.isEmpty) continue;

      final path = EdgePathUtil.createEdgePath(edge, source, target);
      if (EdgePathUtil.isPointNearPath(path, position)) {
        return edge.id;
      }
    }
    return null;
  }
}

class _CanvasControls extends StatelessWidget {
  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;
  final VoidCallback onReset;

  const _CanvasControls({
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CanvasToolButton(
              icon: Icons.remove,
              tooltip: 'Zoom out',
              onPressed: onZoomOut,
            ),
            Container(
              width: 54,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s1),
              child: Text(
                '${(scale * 100).round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _CanvasToolButton(
              icon: Icons.add,
              tooltip: 'Zoom in',
              onPressed: onZoomIn,
            ),
            const SizedBox(width: AppTokens.s1),
            _CanvasToolButton(
              key: const Key('btn_canvas_fit'),
              icon: Icons.fit_screen,
              tooltip: 'Fit to screen',
              onPressed: onFit,
            ),
            _CanvasToolButton(
              icon: Icons.center_focus_strong,
              tooltip: 'Reset zoom',
              onPressed: onReset,
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CanvasToolButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 17),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
    );
  }
}

class _CanvasMiniMap extends StatelessWidget {
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final Matrix4 transform;
  final Size viewportSize;
  final Size canvasSize;
  final Size nodeSize;

  const _CanvasMiniMap({
    required this.nodes,
    required this.edges,
    required this.transform,
    required this.viewportSize,
    required this.canvasSize,
    required this.nodeSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('canvas_minimap'),
      width: 180,
      height: 126,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        child: CustomPaint(
          painter: _MiniMapPainter(
            nodes: nodes,
            edges: edges,
            transform: transform,
            viewportSize: viewportSize,
            canvasSize: canvasSize,
            nodeSize: nodeSize,
            colorScheme: theme.colorScheme,
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.s2),
              child: Text(
                'Map',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final Matrix4 transform;
  final Size viewportSize;
  final Size canvasSize;
  final Size nodeSize;
  final ColorScheme colorScheme;

  const _MiniMapPainter({
    required this.nodes,
    required this.edges,
    required this.transform,
    required this.viewportSize,
    required this.canvasSize,
    required this.nodeSize,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.22);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final bounds = _worldBounds();
    final scale = _fitScale(bounds, size);
    final offset = Offset(
      (size.width - bounds.width * scale) / 2 - bounds.left * scale,
      (size.height - bounds.height * scale) / 2 - bounds.top * scale,
    );

    Offset mapPoint(Offset worldPoint) {
      return Offset(
        worldPoint.dx * scale + offset.dx,
        worldPoint.dy * scale + offset.dy,
      );
    }

    final edgePaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.20)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final source = _findNode(edge.sourceNodeId);
      final target = _findNode(edge.targetNodeId);
      if (source == null || target == null) continue;
      canvas.drawLine(
        mapPoint(
            Offset(source.x + nodeSize.width, source.y + nodeSize.height / 2)),
        mapPoint(Offset(target.x, target.y + nodeSize.height / 2)),
        edgePaint,
      );
    }

    for (final node in nodes) {
      final rect = Rect.fromLTWH(
        node.x * scale + offset.dx,
        node.y * scale + offset.dy,
        nodeSize.width * scale,
        nodeSize.height * scale,
      );
      final color = _nodeColor(node.type);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = color.withValues(alpha: 0.78),
      );
    }

    final viewport = _viewportWorldRect();
    if (viewport != null) {
      final viewportRect = Rect.fromPoints(
        mapPoint(viewport.topLeft),
        mapPoint(viewport.bottomRight),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(viewportRect, const Radius.circular(4)),
        Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.10)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(viewportRect, const Radius.circular(4)),
        Paint()
          ..color = colorScheme.primary
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke,
      );
    }
  }

  Rect _worldBounds() {
    if (nodes.isEmpty) return Offset.zero & canvasSize;

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final node in nodes) {
      minX = minX < node.x ? minX : node.x;
      minY = minY < node.y ? minY : node.y;
      maxX = maxX > node.x + nodeSize.width ? maxX : node.x + nodeSize.width;
      maxY = maxY > node.y + nodeSize.height ? maxY : node.y + nodeSize.height;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(220);
  }

  double _fitScale(Rect bounds, Size size) {
    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  Rect? _viewportWorldRect() {
    if (viewportSize == Size.zero) return null;
    final inverse = Matrix4.tryInvert(transform);
    if (inverse == null) return null;

    final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      inverse,
      Offset(viewportSize.width, viewportSize.height),
    );
    return Rect.fromPoints(topLeft, bottomRight);
  }

  WorkflowNode? _findNode(String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  Color _nodeColor(String type) {
    switch (type) {
      case 'start':
        return Colors.green;
      case 'end':
        return Colors.redAccent;
      case 'api':
        return Colors.blue;
      case 'condition':
        return Colors.orange;
      case 'gql_request':
        return Colors.pink;
      case 'ws_connect':
      case 'ws_send':
      case 'ws_wait':
        return Colors.deepPurple;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.transform != transform ||
        oldDelegate.viewportSize != viewportSize ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    const step = 20.0;
    const radius = 1.0;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
