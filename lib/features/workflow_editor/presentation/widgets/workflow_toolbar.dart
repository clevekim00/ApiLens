import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../../application/workflow_editor_controller.dart';
import '../../data/sample_workflows.dart';
import 'workflow_actions.dart';

class WorkflowToolbar extends ConsumerStatefulWidget {
  const WorkflowToolbar({super.key});

  @override
  ConsumerState<WorkflowToolbar> createState() => _WorkflowToolbarState();
}

class _WorkflowToolbarState extends ConsumerState<WorkflowToolbar> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameFocusNode = FocusNode()..addListener(_commitNameWhenBlurred);
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_commitNameWhenBlurred);
    _nameFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _commitNameWhenBlurred() {
    if (!_nameFocusNode.hasFocus) {
      _commitName();
    }
  }

  void _commitName() {
    final nextName = _nameController.text.trim();
    final currentName = ref.read(workflowEditorProvider).name;
    final safeName = nextName.isEmpty ? 'Untitled Workflow' : nextName;

    if (safeName != currentName) {
      ref.read(workflowEditorProvider.notifier).updateName(safeName);
    }

    if (_nameController.text != safeName) {
      _nameController.text = safeName;
      _nameController.selection = TextSelection.collapsed(
        offset: _nameController.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workflowEditorProvider);
    final theme = Theme.of(context);

    if (!_nameFocusNode.hasFocus && _nameController.text != state.name) {
      _nameController.text = state.name;
      _nameController.selection = TextSelection.collapsed(
        offset: _nameController.text.length,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;
        final veryCompact = constraints.maxWidth < 640;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      ),
                      child: Icon(
                        Icons.account_tree_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s2),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: veryCompact ? 180 : 280,
                        minWidth: 130,
                      ),
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        onSubmitted: (_) => _commitName(),
                        textInputAction: TextInputAction.done,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Workflow name',
                          filled: true,
                          fillColor: theme.colorScheme.primary
                              .withValues(alpha: 0.035),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.s2,
                            vertical: AppTokens.s1,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusMd),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusMd),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                      ),
                    ),
                    if (!veryCompact) ...[
                      const SizedBox(width: AppTokens.s2),
                      _SaveStateBadge(
                        isDirty: state.isDirty,
                        lastSavedAt: state.lastSavedAt,
                      ),
                    ],
                  ],
                ),
              ),
              if (!veryCompact)
                _ToolbarAction(
                  icon: Icons.science_outlined,
                  label: 'Samples',
                  compact: compact,
                  onPressed: () => _showSamplesDialog(context),
                ),
              const SizedBox(width: AppTokens.s1),
              _ToolbarAction(
                icon: Icons.add,
                label: 'New',
                compact: compact,
                onPressed: () => WorkflowActions.handleNew(context, ref),
              ),
              _ToolbarAction(
                icon: Icons.folder_open_outlined,
                label: 'Open',
                compact: compact,
                onPressed: () => WorkflowActions.handleOpen(context, ref),
              ),
              _ToolbarAction(
                icon: Icons.save_outlined,
                label: 'Save',
                compact: compact,
                onPressed: () =>
                    WorkflowActions.handleSave(context, ref, saveAs: false),
              ),
              _ToolbarAction(
                icon: Icons.play_arrow_rounded,
                label: 'Run',
                compact: compact,
                emphasized: true,
                onPressed: () => WorkflowActions.handleRun(context, ref),
              ),
              _WorkflowOverflowMenu(
                showSamples: veryCompact,
                onSamples: () => _showSamplesDialog(context),
                onSaveAs: () =>
                    WorkflowActions.handleSave(context, ref, saveAs: true),
                onExport: () => WorkflowActions.handleExport(context, ref),
                onImport: () => WorkflowActions.handleImport(context, ref),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSamplesDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          title: const Text('Load Sample Workflow'),
          content: SizedBox(
            width: 460,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: SampleWorkflows.samples.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s2),
              itemBuilder: (context, index) {
                final workflow = SampleWorkflows.samples[index];

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    onTap: () {
                      ref.read(workflowEditorProvider.notifier).loadWorkflow(
                            workflow.id,
                            workflow.name,
                            workflow.nodes,
                            workflow.edges,
                            groupId: workflow.groupId,
                          );
                      Navigator.of(dialogContext).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppTokens.s3),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.035),
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schema_outlined,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppTokens.s2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workflow.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${workflow.nodes.length} nodes / ${workflow.edges.length} edges',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.58),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SaveStateBadge extends StatelessWidget {
  final bool isDirty;
  final DateTime? lastSavedAt;

  const _SaveStateBadge({
    required this.isDirty,
    required this.lastSavedAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDirty ? Colors.orange : Colors.green;
    final label = isDirty ? 'Unsaved' : _savedLabel(lastSavedAt);

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.20)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: AppTokens.s1),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _savedLabel(DateTime? dateTime) {
    if (dateTime == null) return 'Not saved';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return 'Saved $hour:$minute';
  }
}

class _ToolbarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;
  final bool emphasized;
  final VoidCallback onPressed;

  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.compact,
    required this.onPressed,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: label,
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        color: emphasized ? Colors.green.shade600 : null,
      );
    }

    if (emphasized) {
      return Padding(
        padding: const EdgeInsets.only(left: AppTokens.s1),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 17),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: AppTokens.s1),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
      ),
    );
  }
}

class _WorkflowOverflowMenu extends StatelessWidget {
  final bool showSamples;
  final VoidCallback onSamples;
  final VoidCallback onSaveAs;
  final VoidCallback onExport;
  final VoidCallback onImport;

  const _WorkflowOverflowMenu({
    required this.showSamples,
    required this.onSamples,
    required this.onSaveAs,
    required this.onExport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_WorkflowMenuAction>(
      tooltip: 'Workflow actions',
      icon: const Icon(Icons.more_horiz),
      onSelected: (action) {
        switch (action) {
          case _WorkflowMenuAction.samples:
            onSamples();
          case _WorkflowMenuAction.saveAs:
            onSaveAs();
          case _WorkflowMenuAction.export:
            onExport();
          case _WorkflowMenuAction.import:
            onImport();
        }
      },
      itemBuilder: (context) => [
        if (showSamples)
          const PopupMenuItem(
            value: _WorkflowMenuAction.samples,
            child: Text('Samples'),
          ),
        const PopupMenuItem(
          value: _WorkflowMenuAction.saveAs,
          child: Text('Save as'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _WorkflowMenuAction.export,
          child: Text('Export JSON'),
        ),
        const PopupMenuItem(
          value: _WorkflowMenuAction.import,
          child: Text('Import JSON'),
        ),
      ],
    );
  }
}

enum _WorkflowMenuAction { samples, saveAs, export, import }
