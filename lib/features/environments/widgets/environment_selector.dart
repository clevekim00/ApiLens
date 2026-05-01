import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/tokens/app_tokens.dart';
import '../../environments/providers/environment_provider.dart';
import '../../environments/screens/environment_manager_screen.dart';

class EnvironmentSelector extends ConsumerWidget {
  const EnvironmentSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listAsync = ref.watch(environmentListProvider);
    final activeId = ref.watch(activeEnvironmentIdProvider);

    return listAsync.when(
      data: (list) {
        return Container(
          height: 32,
          constraints: const BoxConstraints(minWidth: 190, maxWidth: 250),
          padding: const EdgeInsets.only(left: AppTokens.s2),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: activeId != null && list.any((e) => e.id == activeId)
                        ? activeId.toString()
                        : null,
                    hint: const Text('No Environment'),
                    isExpanded: true,
                    isDense: true,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No Environment'),
                      ),
                      ...list.map((e) => DropdownMenuItem<String>(
                            value: e.id.toString(),
                            child: Text(
                              e.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (val) {
                      final id = val != null ? int.parse(val) : null;
                      ref
                          .read(environmentListProvider.notifier)
                          .activateEnvironment(id);
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 18),
                tooltip: 'Manage Environments',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const EnvironmentManagerScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => Icon(
        Icons.error_outline,
        color: theme.colorScheme.error,
        size: 18,
      ),
    );
  }
}
