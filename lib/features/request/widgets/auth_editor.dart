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
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Authentication Type:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AuthType>(
                    value: authType,
                    dropdownColor: theme.cardColor,
                    style: theme.textTheme.bodyMedium,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (authType == AuthType.bearer) ...[
            _buildBearerInput(ref, authData, theme),
          ] else if (authType == AuthType.basic) ...[
            _buildBasicInput(ref, authData, theme),
          ] else if (authType == AuthType.apiKey) ...[
            _buildApiKeyInput(ref, authData, theme),
          ] else ...[
             Padding(
               padding: const EdgeInsets.only(top: 32.0),
               child: Center(
                 child: Text(
                   'No authentication selected.', 
                   style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)
                 ),
               ),
             ),
          ],
        ],
      ),
    );
  }

  Widget _buildBearerInput(WidgetRef ref, Map<String, String> data, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Token', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: data['token'],
          decoration: const InputDecoration(
            hintText: 'e.g. eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
          ),
          style: const TextStyle(fontFamily: 'Fira Code', fontSize: 13),
          onChanged: (val) {
            final newData = Map<String, String>.from(data);
            newData['token'] = val;
            ref.read(requestNotifierProvider.notifier).updateAuthData(newData);
          },
        ),
      ],
    );
  }

  Widget _buildBasicInput(WidgetRef ref, Map<String, String> data, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Username', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: data['username'],
          decoration: const InputDecoration(),
          style: const TextStyle(fontFamily: 'Fira Code', fontSize: 13),
          onChanged: (val) {
            final newData = Map<String, String>.from(data);
            newData['username'] = val;
            ref.read(requestNotifierProvider.notifier).updateAuthData(newData);
          },
        ),
        const SizedBox(height: 16),
        Text('Password', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: data['password'],
          obscureText: true,
          decoration: const InputDecoration(),
          style: const TextStyle(fontFamily: 'Fira Code', fontSize: 13),
          onChanged: (val) {
            final newData = Map<String, String>.from(data);
            newData['password'] = val;
            ref.read(requestNotifierProvider.notifier).updateAuthData(newData);
          },
        ),
      ],
    );
  }
  
  Widget _buildApiKeyInput(WidgetRef ref, Map<String, String> data, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Key', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: data['key'],
                    style: const TextStyle(fontFamily: 'Fira Code', fontSize: 13),
                    onChanged: (val) {
                       final newData = Map<String, String>.from(data);
                       newData['key'] = val;
                       ref.read(requestNotifierProvider.notifier).updateAuthData(newData);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Value', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: data['value'],
                    style: const TextStyle(fontFamily: 'Fira Code', fontSize: 13),
                    onChanged: (val) {
                       final newData = Map<String, String>.from(data);
                       newData['value'] = val;
                       ref.read(requestNotifierProvider.notifier).updateAuthData(newData);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Add to', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: data['addTo'] ?? 'Header',
              dropdownColor: theme.cardColor,
              style: theme.textTheme.bodyMedium,
              isExpanded: true,
              items: ['Header', 'Query Params'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
               onChanged: (val) {
                 if (val != null) {
                    final newData = Map<String, String>.from(data);
                    newData['addTo'] = val;
                    ref.read(requestNotifierProvider.notifier).updateAuthData(newData);
                 }
               },
            ),
          ),
        ),
      ],
    );
  }
}
