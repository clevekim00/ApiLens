
import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';

class AppInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool mono;
  final bool readOnly;
  final int? maxLines;
  final TextInputType? keyboardType;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const AppInput({
    super.key,
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.mono = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onEditingComplete,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    // Theme handles the border and fill logic
    final style = mono ? AppTokens.monoStyle : AppTokens.textTheme.bodyMedium;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      onChanged: onChanged,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      style: style?.copyWith(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        isDense: true, 
      ),
    );
  }
}
