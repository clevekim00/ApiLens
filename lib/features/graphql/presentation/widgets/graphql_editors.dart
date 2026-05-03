import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/components/app_code_editor_shell.dart';
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
    return AppCodeEditorShell(
      controller: _controller,
      hint: widget.hint,
      onChanged: (value) {
        widget.onChanged(value);
        setState(() {});
      },
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
  final String? validationError;
  final VoidCallback onFormat;

  const GraphQLVariablesEditor({
    super.key,
    required this.variables,
    required this.onChanged,
    required this.validationError,
    required this.onFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasError = validationError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: AppTokens.s2),
          child: Wrap(
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ValidationStatusChip(
                hasError: hasError,
                message: validationError ?? 'Variables JSON is valid',
              ),
              TextButton.icon(
                onPressed: onFormat,
                icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                label: const Text('Format JSON'),
              ),
              Text(
                'Variables must be a JSON object.',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: CodeEditor(
            initialValue: variables,
            onChanged: onChanged,
            hint: '{\n  "id": "1"\n}',
          ),
        ),
      ],
    );
  }
}

class _ValidationStatusChip extends StatelessWidget {
  final bool hasError;
  final String message;

  const _ValidationStatusChip({
    required this.hasError,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hasError ? theme.colorScheme.error : Colors.green;

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s2,
        vertical: AppTokens.s1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasError ? Icons.error_outline : Icons.check_circle_outline,
            size: 15,
            color: color,
          ),
          const SizedBox(width: AppTokens.s1),
          Flexible(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
