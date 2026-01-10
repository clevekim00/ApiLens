import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apilens/features/request/models/request_model.dart';
import 'package:apilens/features/request/providers/request_provider.dart';

class AuthEditor extends ConsumerWidget {
  const AuthEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authType = ref.watch(requestNotifierProvider.select((s) => s.authType));
    final authData = ref.watch(requestNotifierProvider.select((s) => s.authData ?? {}));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<AuthType>(
                value: authType,
                items: AuthType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(requestNotifierProvider.notifier).updateAuthType(val);
                  }
                },
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          
          if (authType == AuthType.bearer) ...[
            _buildBearerInput(ref, authData),
          ] else if (authType == AuthType.basic) ...[
            _buildBasicInput(ref, authData),
          ] else if (authType == AuthType.apiKey) ...[
            _buildApiKeyInput(ref, authData),
          ] else ...[
             const Text('No authentication selected.', style: TextStyle(color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _buildBearerInput(WidgetRef ref, Map<String, String> data) {
    return TextFormField(
      initialValue: data['token'],
      decoration: const InputDecoration(
        labelText: 'Bearer Token',
        border: OutlineInputBorder(),
      ),
      onChanged: (val) {
        final newData = Map<String, String>.from(data);
        newData['token'] = val;
        ref.read(requestNotifierProvider.notifier).updateAuthData(newData);
      },
    );
  }

  Widget _buildBasicInput(WidgetRef ref, Map<String, String> data) {
    return Column(
      children: [
        TextFormField(
          initialValue: data['username'],
          decoration: const InputDecoration(labelText: 'Username'),
          onChanged: (val) {
            final newData = Map<String, String>.from(data);
            newData['username'] = val;
            ref.read(requestNotifierProvider.notifier).updateAuthData(newData);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: data['password'],
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
          onChanged: (val) {
            final newData = Map<String, String>.from(data);
            newData['password'] = val;
            ref.read(requestNotifierProvider.notifier).updateAuthData(newData);
          },
        ),
      ],
    );
  }
  
  Widget _buildApiKeyInput(WidgetRef ref, Map<String, String> data) {
    return Column(
      children: [
        TextFormField(
          initialValue: data['key'],
          decoration: const InputDecoration(labelText: 'Key'),
          onChanged: (val) {
             final newData = Map<String, String>.from(data);
             newData['key'] = val;
             ref.read(requestNotifierProvider.notifier).updateAuthData(newData);
          },
        ),
         const SizedBox(height: 16),
        TextFormField(
          initialValue: data['value'],
          decoration: const InputDecoration(labelText: 'Value'),
          onChanged: (val) {
             final newData = Map<String, String>.from(data);
             newData['value'] = val;
             ref.read(requestNotifierProvider.notifier).updateAuthData(newData);
          },
        ),
        const SizedBox(height: 16),
        DropdownButton<String>(
          value: data['addTo'] ?? 'Header',
          items: ['Header', 'Query Params'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
           onChanged: (val) {
             if (val != null) {
                final newData = Map<String, String>.from(data);
                newData['addTo'] = val;
                ref.read(requestNotifierProvider.notifier).updateAuthData(newData);
             }
           },
        ),
      ],
    );
  }
}
