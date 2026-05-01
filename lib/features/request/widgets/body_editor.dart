import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../models/request_model.dart';
import '../providers/request_provider.dart';

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
      final formatted = const JsonEncoder.withIndent('  ').convert(parsed);
      _controller.text = formatted;
      ref.read(requestNotifierProvider.notifier).updateBody(formatted);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid JSON')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyType =
        ref.watch(requestNotifierProvider.select((state) => state.bodyType));
    final requestBody =
        ref.watch(requestNotifierProvider.select((state) => state.body));
    final theme = Theme.of(context);

    ref.listen<String?>(
      requestNotifierProvider.select((state) => state.body),
      (previous, next) {
        final nextText = next ?? '';
        if (nextText != _controller.text) {
          _controller.text = nextText;
        }
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BodyToolbar(
          bodyType: bodyType,
          byteCount: (requestBody ?? '').length,
          onTypeChanged: (type) {
            ref.read(requestNotifierProvider.notifier).updateBodyType(type);
          },
          onPrettyPrint: bodyType == RequestBodyType.json ? _prettyPrint : null,
        ),
        Expanded(
          child: bodyType == RequestBodyType.none
              ? _NoBodyState(theme: theme)
              : _CodeEditor(
                  controller: _controller,
                  bodyType: bodyType,
                  onChanged: (value) {
                    ref
                        .read(requestNotifierProvider.notifier)
                        .updateBody(value);
                    setState(() {});
                  },
                ),
        ),
      ],
    );
  }
}

class _BodyToolbar extends StatelessWidget {
  final RequestBodyType bodyType;
  final int byteCount;
  final ValueChanged<RequestBodyType> onTypeChanged;
  final VoidCallback? onPrettyPrint;

  const _BodyToolbar({
    required this.bodyType,
    required this.byteCount,
    required this.onTypeChanged,
    this.onPrettyPrint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s3,
        vertical: AppTokens.s2,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.025),
          theme.colorScheme.surface,
        ),
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Wrap(
        spacing: AppTokens.s2,
        runSpacing: AppTokens.s2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Body',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<RequestBodyType>(
                value: bodyType,
                isDense: true,
                style: theme.textTheme.bodyMedium,
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                items: RequestBodyType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) onTypeChanged(value);
                },
              ),
            ),
          ),
          _BodyMetaChip(label: '$byteCount bytes'),
          if (onPrettyPrint != null)
            TextButton.icon(
              onPressed: onPrettyPrint,
              icon: const Icon(Icons.format_align_left, size: 16),
              label: const Text('Format JSON'),
            ),
        ],
      ),
    );
  }
}

class _BodyMetaChip extends StatelessWidget {
  final String label;

  const _BodyMetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CodeEditor extends StatelessWidget {
  final TextEditingController controller;
  final RequestBodyType bodyType;
  final ValueChanged<String> onChanged;

  const _CodeEditor({
    required this.controller,
    required this.bodyType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineCount = controller.text.isEmpty
        ? 1
        : '\n'.allMatches(controller.text).length + 1;
    final lineNumbers =
        List.generate(lineCount, (index) => '${index + 1}').join('\n');

    return ColoredBox(
      color: Color.alphaBlend(
        theme.brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.50),
        theme.scaffoldBackgroundColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 48,
            padding:
                const EdgeInsets.only(top: AppTokens.s3, right: AppTokens.s2),
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
            child: TextFormField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: AppTokens.monoStyle.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.5,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppTokens.s3),
                hintText: _hintFor(bodyType),
                filled: false,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  String _hintFor(RequestBodyType bodyType) {
    switch (bodyType) {
      case RequestBodyType.json:
        return '{\n  "hello": "world"\n}';
      case RequestBodyType.form:
        return 'key=value&another=value';
      case RequestBodyType.text:
        return 'Plain text request body...';
      case RequestBodyType.none:
        return '';
    }
  }
}

class _NoBodyState extends StatelessWidget {
  final ThemeData theme;

  const _NoBodyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block_outlined,
              size: 34,
              color: theme.colorScheme.primary.withValues(alpha: 0.62),
            ),
            const SizedBox(height: AppTokens.s3),
            Text(
              'No body',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTokens.s1),
            Text(
              'Choose JSON, Text, or Form to add a payload.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
