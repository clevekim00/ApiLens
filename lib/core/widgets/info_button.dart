import 'package:flutter/material.dart';
import '../../core/ui/tokens/app_tokens.dart';

class InfoButton extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const InfoButton({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return IconButton(
      icon: Icon(icon, size: 16),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: AppTokens.s2),
                Text(title),
              ],
            ),
            content: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      },
      tooltip: 'Learn more about $title',
      color: theme.colorScheme.primary.withValues(alpha: 0.7),
    );
  }
}
