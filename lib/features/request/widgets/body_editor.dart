import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apilens/features/request/models/request_model.dart';
import 'package:apilens/features/request/providers/request_provider.dart';

class BodyEditor extends ConsumerStatefulWidget {
  const BodyEditor({super.key});

  @override
  ConsumerState<BodyEditor> createState() => _BodyEditorState();
}

class _BodyEditorState extends ConsumerState<BodyEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller with current state
    final request = ref.read(requestNotifierProvider);
    _controller = TextEditingController(text: request.body ?? '');
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _prettyPrint() {
    try {
      final dynamic parsed = jsonDecode(_controller.text);
      final String formatted = const JsonEncoder.withIndent('  ').convert(parsed);
      _controller.text = formatted;
      // Also update state
      ref.read(requestNotifierProvider.notifier).updateBody(formatted);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid JSON')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyType = ref.watch(requestNotifierProvider.select((s) => s.bodyType));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              // Body Type Dropdown
              DropdownButton<RequestBodyType>(
                value: bodyType,
                items: RequestBodyType.values.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(requestNotifierProvider.notifier).updateBodyType(val);
                  }
                },
              ),
              const Spacer(),
              // Pretty Print Button
              if (bodyType == RequestBodyType.json)
                TextButton.icon(
                  onPressed: _prettyPrint,
                  icon: const Icon(Icons.format_align_left),
                  label: const Text('Pretty'),
                ),
            ],
          ),
        ),
        
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: bodyType == RequestBodyType.none
                ? const Center(child: Text('No Body'))
                : TextFormField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter request body...',
                    ),
                    onChanged: (val) {
                      ref.read(requestNotifierProvider.notifier).updateBody(val);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
