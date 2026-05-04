import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../request/providers/request_provider.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import '../../../../core/ui/components/app_input.dart';
import '../../../../core/widgets/info_button.dart';

class MethodSelector extends ConsumerWidget {
  const MethodSelector({super.key});

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET': return AppColorsLight.ring; // Blue
      case 'POST': return Colors.green;
      case 'PUT': return Colors.orange;
      case 'DELETE': return AppColorsLight.destructive;
      case 'PATCH': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(requestNotifierProvider.select((s) => s.method));
    
    return Row(
      children: [
        Container(
          width: 110,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: method,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16),
              style: AppTokens.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getMethodColor(method),
              ),
              items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
                  .map((m) => DropdownMenuItem(
                        value: m, 
                        child: Text(
                          m, 
                          style: AppTokens.textTheme.bodyMedium?.copyWith(color: _getMethodColor(m), fontWeight: FontWeight.bold)
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(requestNotifierProvider.notifier).updateMethod(val);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s2),
        const InfoButton(
          title: 'HTTP Methods',
          message: 'GET: Retrieve data\nPOST: Create new data\nPUT: Replace existing data\nPATCH: Partial update\nDELETE: Remove data',
        ),
      ],
    );
  }
}

class UrlInput extends ConsumerStatefulWidget {
  final VoidCallback? onSubmitted;
  const UrlInput({super.key, this.onSubmitted});

  @override
  ConsumerState<UrlInput> createState() => _UrlInputState();
}

class _UrlInputState extends ConsumerState<UrlInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(requestNotifierProvider).url,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes to update controller if needed (avoid loop)
    ref.listen(requestNotifierProvider.select((s) => s.url), (prev, next) {
      if (next != _controller.text) {
        _controller.text = next;
      }
    });

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: AppInput(
              controller: _controller,
              hintText: 'https://api.example.com/v1/resource',
              mono: true,
              onChanged: (val) => ref.read(requestNotifierProvider.notifier).updateUrl(val),
              onSubmitted: (_) => widget.onSubmitted?.call(),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s2),
        const InfoButton(
          title: 'Dynamic URLs',
          message: 'You can use environment variables in your URL.\n\nExample: {{base_url}}/users/{{id}}\n\nDefine variables in the Environment selector (top right).',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
