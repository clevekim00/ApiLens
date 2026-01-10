import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../request/providers/request_provider.dart';

class MethodSelector extends ConsumerWidget {
  const MethodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(requestNotifierProvider.select((s) => s.method));
    
    return DropdownButton<String>(
      value: method,
      items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          ref.read(requestNotifierProvider.notifier).updateMethod(val);
        }
      },
      underline: Container(), // Remove underline for cleaner look
    );
  }
}

class UrlInput extends ConsumerWidget {
  const UrlInput({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We use a controller but sync it with state? 
    // Or just onChange. Simple MVP approach: onChange.
    // Ideally we want to initialize with current state.
    
    final currentUrl = ref.watch(requestNotifierProvider.select((s) => s.url));
    
    return TextFormField(
      initialValue: currentUrl,
      decoration: const InputDecoration(
        hintText: 'https://api.example.com/v1/resource',
        border: InputBorder.none, // Cleaner look inside a container
      ),
      onChanged: (val) {
        ref.read(requestNotifierProvider.notifier).updateUrl(val);
      },
    );
  }
}
