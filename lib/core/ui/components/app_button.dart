import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive, outline }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool disabled;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.disabled = false,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // We map variants to specific ButtonStyles
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ButtonStyle style;

    switch (variant) {
      case AppButtonVariant.primary:
        style = ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
        );
        break;
      case AppButtonVariant.secondary:
        style = ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          elevation: 0,
        );
        break;
      case AppButtonVariant.ghost:
        style = TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
        );
        break;
      case AppButtonVariant.destructive:
        style = ElevatedButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          elevation: 0,
        );
        break;
      case AppButtonVariant.outline:
        style = OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: theme.dividerColor),
        );
        break;
    }

    // Common Overrides
    style = style.copyWith(
      minimumSize: WidgetStateProperty.all(const Size(64, 34)),
      padding: WidgetStateProperty.all(
        padding ?? const EdgeInsets.symmetric(horizontal: AppTokens.s4),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
      ),
      textStyle: WidgetStateProperty.all(
        AppTokens.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );

    final childWidget = LayoutBuilder(
      builder: (context, constraints) {
        final canConstrainText = constraints.maxWidth.isFinite;
        final labelText = Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        );

        return Row(
          mainAxisSize: canConstrainText ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) icon!,
            if (icon != null && label.isNotEmpty) const SizedBox(width: 8),
            if (label.isNotEmpty)
              canConstrainText ? Flexible(child: labelText) : labelText,
          ],
        );
      },
    );

    if (width != null) {
      return SizedBox(
        width: width,
        height: 34,
        child: _buildButton(style, childWidget),
      );
    }

    return SizedBox(height: 34, child: _buildButton(style, childWidget));
  }

  Widget _buildButton(ButtonStyle style, Widget child) {
    if (variant == AppButtonVariant.outline) {
      return OutlinedButton(
          onPressed: disabled ? null : onPressed, style: style, child: child);
    } else if (variant == AppButtonVariant.ghost) {
      return TextButton(
          onPressed: disabled ? null : onPressed, style: style, child: child);
    } else {
      return ElevatedButton(
          onPressed: disabled ? null : onPressed, style: style, child: child);
    }
  }
}
