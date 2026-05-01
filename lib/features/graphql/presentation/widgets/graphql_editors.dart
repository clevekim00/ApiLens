import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/tokens/app_tokens.dart';

class CodeEditor extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hint;

  const CodeEditor({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.hint,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineCount = _controller.text.isEmpty
        ? 1
        : '\n'.allMatches(_controller.text).length + 1;
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
                controller: _controller,
                maxLines: null,
                expands: true,
                style: AppTokens.monoStyle.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppTokens.s3),
                  filled: false,
                ),
                onChanged: (value) {
                  widget.onChanged(value);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GraphQLQueryEditor extends ConsumerWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const GraphQLQueryEditor({
    super.key,
    required this.query,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CodeEditor(
      initialValue: query,
      onChanged: onChanged,
      hint: 'query MyQuery {\n  viewer { id login }\n}',
    );
  }
}

class GraphQLVariablesEditor extends ConsumerWidget {
  final String variables;
  final ValueChanged<String> onChanged;

  const GraphQLVariablesEditor({
    super.key,
    required this.variables,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CodeEditor(
      initialValue: variables,
      onChanged: onChanged,
      hint: '{\n  "id": "1"\n}',
    );
  }
}
