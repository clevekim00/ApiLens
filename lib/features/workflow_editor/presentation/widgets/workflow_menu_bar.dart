import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/workflow_editor_controller.dart';
import 'workflow_actions.dart'; // NEW

class WorkflowMenuBar extends ConsumerWidget {
  const WorkflowMenuBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(workflowEditorProvider);
    final isDirty = editorState.isDirty;
    
    return MenuAnchor(
      builder: (context, controller, child) {
        return FilledButton.icon(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.menu),
          label: Text(editorState.name + (isDirty ? '*' : '')),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent, 
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.add),
          onPressed: () => WorkflowActions.handleNew(context, ref),
          child: const Text('New Workflow'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.save),
          onPressed: () => WorkflowActions.handleSave(context, ref, saveAs: false),
          child: const Text('Save'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.save_as),
          onPressed: () => WorkflowActions.handleSave(context, ref, saveAs: true),
          child: const Text('Save As...'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.folder_open),
          onPressed: () => WorkflowActions.handleOpen(context, ref),
          child: const Text('Open...'),
        ),
        const PopupMenuDivider(),
        MenuItemButton(
          leadingIcon: const Icon(Icons.file_upload), 
          onPressed: () => WorkflowActions.handleImport(context, ref), 
          child: const Text('Import JSON'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.file_download),
          onPressed: () => WorkflowActions.handleExport(context, ref),
          child: const Text('Export JSON'),
        ),
        const PopupMenuDivider(),
        MenuItemButton(
          leadingIcon: const Icon(Icons.play_arrow, color: Colors.green),
          onPressed: () => WorkflowActions.handleRun(context, ref),
          child: const Text('Run Workflow'),
        ),
      ],
    );
  }
}

