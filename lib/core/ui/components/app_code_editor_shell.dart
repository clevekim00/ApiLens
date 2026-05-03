import 'package:flutter/material.dart';

import '../tokens/app_tokens.dart';

class AppCodeEditorShell extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool expands;
  final int? minLines;
  final int? maxLines;

  const AppCodeEditorShell({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint,
    this.expands = true,
    this.minLines,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineCount = controller.text.isEmpty
        ? 1
        : '\n'.allMatches(controller.text).length + 1;
    final lineNumbers =
        List.generate(lineCount, (index) => '${index + 1}').join('\n');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          theme.brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.50),
          theme.scaffoldBackgroundColor,
        ),
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 46,
              padding: const EdgeInsets.only(
                top: AppTokens.s3,
                right: AppTokens.s2,
              ),
              alignment: Alignment.topRight,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(right: BorderSide(color: theme.dividerColor)),
              ),
              child: Text(
                lineNumbers,
                textAlign: TextAlign.right,
                style: AppTokens.monoStyle.copyWith(
                  fontSize: 12,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: expands ? null : minLines,
                maxLines: expands ? null : maxLines,
                expands: expands,
                style: AppTokens.monoStyle.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppTokens.s3),
                  filled: false,
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
