import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/workflow.dart';
import '../../application/workflow_editor_controller.dart';
import '../../data/workflow_repository.dart';
import '../../../execution/application/workflow_runner_controller.dart';

class WorkflowActions {
  static Future<void> handleNew(BuildContext context, WidgetRef ref) async {
    if (ref.read(workflowEditorProvider).isDirty) {
      final discard = await _showDiscardConfirm(context);
      if (!discard) return;
    }
    ref.read(workflowEditorProvider.notifier).clearWorkflow();
  }

  static Future<void> handleSave(BuildContext context, WidgetRef ref, {required bool saveAs}) async {
    final state = ref.read(workflowEditorProvider);
    String name = state.name;
    String id = state.id;

    if (saveAs) {
      final newName = await _showNameDialog(context, 'Save Workflow As', name);
      if (newName == null) return;
      
      final newId = const Uuid().v4();
      
      // Save new file
      final workflow = Workflow(
        id: newId,
        name: newName,
        nodes: state.nodes,
        edges: state.edges,
      );
      await ref.read(workflowRepositoryProvider).save(workflow);
      
      // Switch context to new file
      ref.read(workflowEditorProvider.notifier).saveAs(newId, newName);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved as "$newName"!')));
      }
    } else {
      // Regular Save
      final workflow = Workflow(
        id: id,
        name: name,
        nodes: state.nodes,
        edges: state.edges,
      );
      await ref.read(workflowRepositoryProvider).save(workflow);
      ref.read(workflowEditorProvider.notifier).markSaved();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved "$name"!')));
      }
    }
  }

  static Future<void> handleOpen(BuildContext context, WidgetRef ref) async {
    if (ref.read(workflowEditorProvider).isDirty) {
      final discard = await _showDiscardConfirm(context);
      if (!discard) return;
    }

    final repo = ref.read(workflowRepositoryProvider);
    final workflows = await repo.getAll();

    if (!context.mounted) return;

    final selected = await showDialog<Workflow>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Open Workflow'),
        children: [
          if (workflows.isEmpty) const Padding(
             padding: EdgeInsets.all(16), 
             child: Text('No saved workflows found.'),
          ),
          ...workflows.map((w) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, w),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(w.name),
            ),
          )),
        ],
      ),
    );

    if (selected != null) {
      ref.read(workflowEditorProvider.notifier).loadWorkflow(
        selected.id, selected.name, selected.nodes, selected.edges
      );
    }
  }

  static Future<void> handleExport(BuildContext context, WidgetRef ref) async {
     final state = ref.read(workflowEditorProvider);
     final workflow = Workflow(
       id: state.id,
       name: state.name,
       nodes: state.nodes,
       edges: state.edges,
     );
     final jsonStr = ref.read(workflowRepositoryProvider).exportJson(workflow);
     await Clipboard.setData(ClipboardData(text: jsonStr));
     if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON copied to clipboard!')));
     }
  }

  static Future<void> handleImport(BuildContext context, WidgetRef ref) async {
    if (ref.read(workflowEditorProvider).isDirty) {
       final discard = await _showDiscardConfirm(context);
       if (!discard) return;
    }

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import JSON'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(hintText: 'Paste JSON here...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Import')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final w = ref.read(workflowRepositoryProvider).importJson(result);
        ref.read(workflowEditorProvider.notifier).loadWorkflow(
          const Uuid().v4(), 
          '${w.name} (Imported)', 
          w.nodes, 
          w.edges
        );
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
        }
      }
    }
  }
  
  static void handleRun(BuildContext context, WidgetRef ref) {
    final state = ref.read(workflowEditorProvider);
    if (!state.nodes.any((n) => n.type == 'start')) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Missing "start" node.')));
       return;
    }
    
    ref.read(workflowRunnerProvider.notifier).run(state.nodes, state.edges);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workflow execution started...')));
  }

  static Future<bool> _showDiscardConfirm(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Discard them?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }
  
  static Future<String?> _showNameDialog(BuildContext context, String title, String initVal) async {
     final controller = TextEditingController(text: initVal);
     return await showDialog<String>(
       context: context,
       builder: (_) => AlertDialog(
         title: Text(title),
         content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Workflow Name')),
         actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('OK')),
         ],
       )
     );
  }
}
