import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../request/providers/request_provider.dart';
import '../../../../core/theme/vscode_theme.dart';

class MethodSelector extends ConsumerWidget {
  const MethodSelector({super.key});

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET': return VSCodeColors.accentBlue;
      case 'POST': return VSCodeColors.accentGreen;
      case 'PUT': return VSCodeColors.accentOrange;
      case 'DELETE': return VSCodeColors.accentRed;
      case 'PATCH': return Colors.purpleAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(requestNotifierProvider.select((s) => s.method));
    
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: method,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: TextStyle(
            color: _getMethodColor(method),
            fontWeight: FontWeight.bold,
            fontFamily: 'Fira Code', // Monospace for tech feel
          ),
          items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
              .map((m) => DropdownMenuItem(
                    value: m, 
                    child: Text(
                      m, 
                      style: TextStyle(color: _getMethodColor(m), fontWeight: FontWeight.bold)
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
    );
  }
}

class UrlInput extends ConsumerStatefulWidget {
  const UrlInput({super.key});

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

    return SizedBox(
      height: 36,
      child: TextField(
        controller: _controller,
        style: const TextStyle(fontFamily: 'Fira Code', fontSize: 13),
        decoration: const InputDecoration(
          hintText: 'https://api.example.com/v1/resource',
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Centered vertically
        ),
        onChanged: (val) {
          ref.read(requestNotifierProvider.notifier).updateUrl(val);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
