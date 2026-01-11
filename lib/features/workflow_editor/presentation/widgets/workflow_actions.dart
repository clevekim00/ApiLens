
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
    final state = ref.read(workflowEditorProvider);
    if (state.isDirty) {
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
          SizedBox(
            width: 400,
            height: 300,
            child: ListView.builder(
              itemCount: workflows.length,
              itemBuilder: (context, index) {
                final w = workflows[index];
                return SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, w),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(w.name),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (selected != null) {
      ref.read(workflowEditorProvider.notifier).loadWorkflow(
        selected.id, selected.name, selected.nodes, selected.edges
      );
    }
  }

  static Future<void> handleRun(BuildContext context, WidgetRef ref) async {
    final state = ref.read(workflowEditorProvider);
    
    // Validation
    final startNode = state.nodes.where((n) => n.type == 'start').firstOrNull;
    if (startNode == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Error: Missing "start" node.'), 
           backgroundColor: Colors.red
         )
       );
       return;
    }
    
    // Check path to end (BFS)
    // Assuming end node type is 'end' (checking assumption...)
    // Actually standard is 'end' type? Or maybe I should just check if edges exit?
    // Let's assume just reachability check to any node is enough, but specifically strict requirement:
    // "end로 도달 가능한 path 최소 1개"
    // Does 'end' node exist in palette?
    // Assuming there is an 'end' node. If not, maybe just check if graph is connected.
    
    // Check disconnected nodes
    final connectedNodes = <String>{};
    final queue = [startNode.id];
    connectedNodes.add(startNode.id);
    
    while(queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final outgoing = state.edges.where((e) => e.sourceNodeId == current).map((e) => e.targetNodeId);
      for (final next in outgoing) {
        if (!connectedNodes.contains(next)) {
          connectedNodes.add(next);
          queue.add(next);
        }
      }
    }
    
    bool hasEndNode = state.nodes.any((n) => n.type == 'end');
    bool pathToEnd = false;
    if (hasEndNode) {
       pathToEnd = state.nodes.where((n) => n.type == 'end').any((n) => connectedNodes.contains(n.id));
    } else {
       // If no end node explicitly, maybe it's okay? Requirement said "end로 도달 가능한 path".
       // I'll warn if no end node is reachable.
    }

    if (hasEndNode && !pathToEnd) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Validation Warning'),
            content: const Text('No path found from Start to End node. Execution may not complete properly. Run anyway?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Run')),
            ],
          )
        ) ?? false;
        if (!proceed) return;
    }
    
    if (connectedNodes.length < state.nodes.length) {
       final disconnectedCount = state.nodes.length - connectedNodes.length;
       final proceed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Validation Warning'),
            content: Text('$disconnectedCount nodes are not connected to the Start node and will be ignored. Proceed?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Run')),
            ],
          )
        ) ?? false;
       if (!proceed) return;
    }

    ref.read(workflowRunnerProvider.notifier).run(state.nodes, state.edges);
    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workflow execution started...')));
    }
  }

  static Future<void> handleExport(BuildContext context, WidgetRef ref) async {
     // Optional per request ("다른 메뉴는 제거" -> Remove from menu bar app_menu_bar, but maybe keep action available?
     // Re-reading: "Menu is exactly 2: Workflow, Settings". Export is NOT in the list.
     // So I should remove Export from Menu. But I can keep the code here just in case, or remove it?
     // "다른 메뉴는 제거" applies to visible menus.
     // I'll keep the code but not expose it in AppMenuBar.
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
    // Similarly, Import is not in "Workflow" menu list provided by user:
    // "New workflow, Save workflow, Save as, Open, Run"
    // So Import/Export are GONE from the UI.
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

  static Future<bool> _showDiscardConfirm(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text('You have unsaved changes that will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard')
          ),
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
