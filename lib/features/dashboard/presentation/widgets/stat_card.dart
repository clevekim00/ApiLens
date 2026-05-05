import 'package:flutter/material.dart';
import '../../../../core/ui/tokens/app_tokens.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool isPositive;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.trend,
    required this.isPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTokens.s4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171F33) : Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3449) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.s2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s2,
                    vertical: AppTokens.s1,
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          trend,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark ? const Color(0xFF958EA0) : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
