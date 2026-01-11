
import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool isSelected;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? backgroundColor;

  const AppCard({
    super.key, 
    required this.child, 
    this.padding = const EdgeInsets.all(16.0),
    this.isSelected = false,
    this.onTap,
    this.width,
    this.height,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected ? theme.colorScheme.primary : theme.dividerColor;
    final borderWidth = 1.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.cardColor,
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          boxShadow: isSelected 
            ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.1), blurRadius: 4, spreadRadius: 0)]
            : [],
        ),
        child: child,
      ),
    );
  }
}
