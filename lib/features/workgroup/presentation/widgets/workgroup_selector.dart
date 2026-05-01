import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/workgroup_controller.dart';
import '../../../request/providers/request_provider.dart';

class WorkgroupSelector extends ConsumerWidget {
  const WorkgroupSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(workgroupControllerProvider);
    final request = ref.watch(requestNotifierProvider);

    // Filter out groups? No, show all.
    // Maybe sort by system then name?
    final sortedGroups = List.of(groups);
    sortedGroups.sort((a, b) {
      if (a.isSystem) return -1;
      if (b.isSystem) return 1;
      return a.name.compareTo(b.name);
    });

    // Ensure the selected value exists in the list to avoid Flutter assertion error
    final bool valueExists = sortedGroups.any((g) => g.id == request.groupId);
    final String? safeValue = valueExists ? request.groupId : (sortedGroups.isNotEmpty ? sortedGroups.first.id : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue, 
          items: sortedGroups.map((g) {
            return DropdownMenuItem(
              value: g.id,
              child: Row(
                children: [
                  Icon(g.isSystem ? Icons.archive : Icons.folder, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text(g.name, style: const TextStyle(fontSize: 13)),
                  if (g.isSystem) const Text(' (Default)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            ref.read(requestNotifierProvider.notifier).updateGroupId(newValue);
          },
          isDense: true,
          hint: const Text('Select Group'), // Should not appear if value is set
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ),
    );
  }
}
