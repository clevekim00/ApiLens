import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

enum AppStatusTone { neutral, info, success, warning, danger }

class AppStatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppStatusTone tone;
  final bool dense;

  const AppStatusChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppStatusTone.neutral,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _toneColor(theme);

    return Container(
      height: dense ? 22 : 28,
      padding:
          EdgeInsets.symmetric(horizontal: dense ? AppTokens.s2 : AppTokens.s3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.26)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canConstrainText = constraints.maxWidth.isFinite;
          final labelText = Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          );

          return Row(
            mainAxisSize:
                canConstrainText ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: dense ? 13 : 15, color: color),
                const SizedBox(width: AppTokens.s1),
              ],
              canConstrainText ? Flexible(child: labelText) : labelText,
            ],
          );
        },
      ),
    );
  }

  Color _toneColor(ThemeData theme) {
    switch (tone) {
      case AppStatusTone.neutral:
        return theme.colorScheme.onSurface.withValues(alpha: 0.68);
      case AppStatusTone.info:
        return theme.colorScheme.primary;
      case AppStatusTone.success:
        return Colors.green;
      case AppStatusTone.warning:
        return Colors.orange;
      case AppStatusTone.danger:
        return theme.colorScheme.error;
    }
  }
}
