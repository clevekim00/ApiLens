
import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';
import 'app_badge.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final int? count;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    this.count,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onToggle,
      // radiusSm for headers inside cards usually? Or just regular rect.
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: AppTokens.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 8),
              AppBadge(
                label: count.toString(), 
                variant: AppBadgeVariant.muted
              ),
            ],
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
