import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    if (oldWidget.initialValue != widget.initialValue && _controller.text != widget.initialValue) {
       _controller.text = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLines: null,
      expands: true,
      style: const TextStyle(fontFamily: 'Fira Code', fontSize: 13),
      decoration: InputDecoration(
        hintText: widget.hint,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class GraphQLQueryEditor extends ConsumerWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const GraphQLQueryEditor({super.key, required this.query, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CodeEditor(
      initialValue: query,
      onChanged: onChanged,
      hint: 'query MyQuery { ... }',
    );
  }
}

class GraphQLVariablesEditor extends ConsumerWidget {
  final String variables;
  final ValueChanged<String> onChanged;

  const GraphQLVariablesEditor({super.key, required this.variables, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CodeEditor(
      initialValue: variables,
      onChanged: onChanged,
      hint: '{ "id": "1" }',
    );
  }
}
