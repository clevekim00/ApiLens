
import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

enum AppBadgeVariant {
  standard, // default
  muted,
  success,
  warning,
  destructive,
  outline
}

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color bgColor;
    Color methodColor;
    Color borderColor = Colors.transparent;

    switch (variant) {
      case AppBadgeVariant.standard:
        bgColor = colorScheme.primary;
        methodColor = colorScheme.onPrimary;
        break;
      case AppBadgeVariant.muted:
        // Use surface variant or secondary
        bgColor = colorScheme.secondary;
        methodColor = colorScheme.onSecondary;
        break;
      case AppBadgeVariant.success:
        bgColor = Colors.green; // Hardcoded or from extensions? Let's use standard green for success
        methodColor = Colors.white;
        break;
      case AppBadgeVariant.warning:
        bgColor = Colors.orange;
        methodColor = Colors.white;
        break;
      case AppBadgeVariant.destructive:
        bgColor = colorScheme.error;
        methodColor = colorScheme.onError;
        break;
      case AppBadgeVariant.outline:
        bgColor = Colors.transparent;
        methodColor = colorScheme.onSurface;
        borderColor = theme.dividerColor;
        break;
    }

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: variant == AppBadgeVariant.outline ? Border.all(color: borderColor) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTokens.textTheme.labelSmall?.copyWith(
          color: methodColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
