import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

class AppToolbar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool bordered;

  const AppToolbar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.s2),
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: bordered ? Border.all(color: theme.dividerColor) : null,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
