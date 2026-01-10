import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../environments/providers/environment_provider.dart';
import '../../environments/screens/environment_manager_screen.dart';

class EnvironmentSelector extends ConsumerWidget {
  const EnvironmentSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(environmentListProvider);
    final activeId = ref.watch(activeEnvironmentIdProvider);

    return listAsync.when(
      data: (list) {
        return Row(
          children: [
            DropdownButton<String>(
              value: activeId != null && list.any((e) => e.id == activeId) ? activeId.toString() : null,
              hint: const Text('No Environment'),
              underline: Container(),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('No Environment'),
                ),
                ...list.map((e) => DropdownMenuItem<String>(
                  value: e.id.toString(),
                  child: Text(e.name),
                )).toList(),
              ],
              onChanged: (val) {
                final id = val != null ? int.parse(val) : null;
                ref.read(environmentListProvider.notifier).activateEnvironment(id);
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings, size: 20),
              tooltip: 'Manage Environments',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EnvironmentManagerScreen()),
                );
              },
            ),
          ],
        );
      },
      loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const Icon(Icons.error, color: Colors.red),
    );
  }
}
