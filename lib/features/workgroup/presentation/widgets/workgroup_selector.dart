import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import '../../application/workgroup_controller.dart';
import '../../../request/providers/request_provider.dart';

class WorkgroupSelector extends ConsumerWidget {
  const WorkgroupSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
    final String? safeValue = valueExists
        ? request.groupId
        : (sortedGroups.isNotEmpty ? sortedGroups.first.id : null);

    return Container(
      height: 32,
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          items: sortedGroups.map((g) {
            return DropdownMenuItem(
              value: g.id,
              child: Row(
                children: [
                  Icon(
                    g.isSystem ? Icons.archive : Icons.folder,
                    size: 16,
                    color: theme.colorScheme.primary.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: AppTokens.s2),
                  Flexible(
                    child: Text(
                      g.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (g.isSystem)
                    Text(
                      ' (Default)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            ref.read(requestNotifierProvider.notifier).updateGroupId(newValue);
          },
          isDense: true,
          hint: const Text('Select Group'), // Should not appear if value is set
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
        ),
      ),
    );
  }
}
