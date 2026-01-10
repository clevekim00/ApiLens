import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

// Simple provider for settings
// In a real app, use shared_preferences or Isar
final timeoutProvider = StateProvider<int>((ref) => 30000); // 30s default
final loggingProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeout = ref.watch(timeoutProvider);
    final logging = ref.watch(loggingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Request Timeout (ms)'),
            subtitle: Text('$timeout ms'),
            trailing: SizedBox(
               width: 100,
               child: TextFormField(
                 initialValue: timeout.toString(),
                 keyboardType: TextInputType.number,
                 onFieldSubmitted: (val) {
                   final parsed = int.tryParse(val);
                   if (parsed != null && parsed > 0) {
                     ref.read(timeoutProvider.notifier).state = parsed;
                   }
                 },
               ),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable Logging'),
            value: logging,
            onChanged: (val) {
              ref.read(loggingProvider.notifier).state = val;
            },
          ),
        ],
      ),
    );
  }
}
