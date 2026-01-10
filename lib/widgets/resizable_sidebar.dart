import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ResizableSidebar extends StatefulWidget {
  final Widget child;
  final double initialWidth;
  final double minWidth;
  final double maxWidth;

  const ResizableSidebar({
    super.key,
    required this.child,
    this.initialWidth = 350,
    this.minWidth = 100,
    this.maxWidth = 600,
  });

  @override
  State<ResizableSidebar> createState() => _ResizableSidebarState();
}

class _ResizableSidebarState extends State<ResizableSidebar> {
  late double _width;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: _width,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withOpacity(0.7),
                  border: Border(
                    right: BorderSide(color: AppTheme.darkBorder.withOpacity(0.5)),
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            onHorizontalDragStart: (_) => setState(() => _isDragging = true),
            onHorizontalDragUpdate: (details) {
              setState(() {
                _width = (_width + details.delta.dx).clamp(widget.minWidth, widget.maxWidth);
              });
            },
            onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
            child: Container(
              width: 4,
              color: _isDragging 
                ? AppTheme.cyanTeal 
                : AppTheme.darkBorder.withOpacity(0.5),
              child: Center(
                child: Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
