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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Text('Type:', style: theme.textTheme.bodySmall),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<RequestBodyType>(
                  value: bodyType,
                  isDense: true,
                  style: theme.textTheme.bodyMedium,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                  items: RequestBodyType.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(requestNotifierProvider.notifier).updateBodyType(val);
                    }
                  },
                ),
              ),
              const Spacer(),
              if (bodyType == RequestBodyType.json)
                IconButton(
                  onPressed: _prettyPrint,
                  icon: const Icon(Icons.format_align_left, size: 16),
                  tooltip: 'Format JSON',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
            ],
          ),
        ),
        
        // Editor Area
        Expanded(
          child: bodyType == RequestBodyType.none
              ? Center(
                  child: Text(
                    'No Body',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  ),
                )
              : Container(
                  color: theme.scaffoldBackgroundColor, // Editor background
                  child: Row(
                    children: [
                      // Gutter (simulated)
                      Container(
                        width: 48,
                        color: theme.colorScheme.surface, // Sidebar color
                        // TODO: Implement actual line numbers in future
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(top: 8, right: 8),
                        child: Text(
                          '1\n2\n3', 
                          style: TextStyle(
                            fontFamily: 'Fira Code', 
                            fontSize: 13, 
                            color: theme.hintColor.withOpacity(0.5),
                            height: 1.5 // Matching text field height
                          )
                        ),
                      ),
                      
                      // Code Input
                      Expanded(
                        child: TextFormField(
                          controller: _controller,
                          maxLines: null,
                          expands: true,
                          style: TextStyle(
                            fontFamily: 'Fira Code',
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color,
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.all(8),
                            hintText: 'Enter request body...',
                            filled: false,
                          ),
                          onChanged: (val) {
                            ref.read(requestNotifierProvider.notifier).updateBody(val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
