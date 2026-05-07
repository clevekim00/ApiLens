import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ui/tokens/app_tokens.dart';
import '../services/command_service.dart';
import '../../features/workflow_editor/data/workflow_repository.dart';
import '../../features/workflow_editor/domain/models/workflow.dart';
import '../../features/workflow_editor/application/workflow_editor_controller.dart';
import '../services/navigation_provider.dart';

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Command Palette',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      pageBuilder: (context, anim1, anim2) => const CommandPalette(),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim1),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;
  List<AppCommand> _results = [];
  List<Workflow> _allWorkflows = [];

  @override
  void initState() {
    super.initState();
    _results = ref.read(commandServiceProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    final staticCommands =
        ref.read(commandServiceProvider.notifier).search(query);

    // Search workflows dynamically using pre-fetched list
    final workflowCommands = _allWorkflows
        .where((w) => w.name.toLowerCase().contains(query.toLowerCase()))
        .map((w) => AppCommand(
              id: 'workflow_${w.id}',
              title: 'Open Workflow: ${w.name}',
              description: 'Switch to the visual editor for this workflow',
              icon: Icons.account_tree_outlined,
              action: () {
                ref.read(workflowEditorProvider.notifier).loadWorkflow(
                    w.id, w.name, w.nodes, w.edges,
                    groupId: w.groupId);
                ref
                    .read(navigationProvider.notifier)
                    .setIndex(1); // Switch to Workflow Tab
              },
              tags: ['workflow', 'flow', w.name],
            ))
        .toList();

    setState(() {
      _results = [...staticCommands, ...workflowCommands];
      _selectedIndex = 0;
    });
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_results.isNotEmpty) {
          _selectedIndex = (_selectedIndex + 1) % _results.length;
        }
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_results.isNotEmpty) {
          _selectedIndex =
              (_selectedIndex - 1 + _results.length) % _results.length;
        }
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_results.isNotEmpty) {
        _executeCommand(_results[_selectedIndex]);
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _executeCommand(AppCommand command) {
    Navigator.pop(context);
    command.action();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch all workflows and update local list for search
    ref.listen(allWorkflowsProvider, (prev, next) {
      next.whenData((workflows) {
        if (mounted) {
          setState(() => _allWorkflows = workflows);
        }
      });
    });

    // Also pre-fetch initially if already loaded
    final workflowsAsync = ref.watch(allWorkflowsProvider);
    workflowsAsync.whenData((workflows) {
      if (_allWorkflows.isEmpty && workflows.isNotEmpty) {
        _allWorkflows = workflows;
      }
    });

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Center(
        child: Container(
          width: 600,
          height: 450,
          margin: const EdgeInsets.all(AppTokens.s6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.all(AppTokens.s4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onQueryChanged,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Type a command or search...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: InputBorder.none,
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const Divider(height: 1),
                // Results List
                Expanded(
                  child: _results.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final command = _results[index];
                            final isSelected = index == _selectedIndex;
                            return _buildCommandTile(
                                command, isSelected, theme);
                          },
                        ),
                ),
                // Footer
                _buildFooter(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommandTile(
      AppCommand command, bool isSelected, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTokens.s2, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: ListTile(
        leading: Icon(
          command.icon,
          size: 20,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          command.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: command.description.isNotEmpty
            ? Text(
                command.description,
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              )
            : null,
        trailing: command.shortcut != null
            ? _buildShortcutBadge(command.shortcut!, isSelected, theme)
            : null,
        onTap: () => _executeCommand(command),
      ),
    );
  }

  Widget _buildShortcutBadge(
      String shortcut, bool isSelected, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.dividerColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        shortcut,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: AppTokens.s2),
          Text(
            'No commands found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s4, vertical: AppTokens.s2),
      color: theme.colorScheme.surface.withValues(alpha: 0.5),
      child: Row(
        children: [
          _buildKeyHint('↑↓', 'to navigate', theme),
          const SizedBox(width: AppTokens.s4),
          _buildKeyHint('↵', 'to select', theme),
          const SizedBox(width: AppTokens.s4),
          _buildKeyHint('esc', 'to close', theme),
        ],
      ),
    );
  }

  Widget _buildKeyHint(String key, String action, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: theme.dividerColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            key,
            style: theme.textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          action,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
