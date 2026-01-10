import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apilens/features/workflow_editor/application/workflow_editor_controller.dart';
import 'package:apilens/features/execution/application/workflow_runner_controller.dart';
import 'package:apilens/features/workflow_editor/presentation/widgets/workflow_toolbar.dart';
import 'widgets/workflow_menu_bar.dart'; 
import 'widgets/workflow_actions.dart'; // NEW
import 'panels/inspector_panel.dart';
import 'panels/node_palette.dart';
import 'panels/debug_panel.dart';
import 'widgets/workflow_canvas.dart';

class WorkflowEditorScreen extends ConsumerWidget {
  const WorkflowEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const WorkflowMenuBar(), 
        centerTitle: false,
        elevation: 0,
        actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FilledButton.icon(
                onPressed: () {
                    final nodes = ref.read(workflowEditorProvider).nodes;
                    final edges = ref.read(workflowEditorProvider).edges;
                    ref.read(workflowRunnerProvider.notifier).run(nodes, edges);
                }, 
                icon: const Icon(Icons.play_arrow), 
                label: const Text('Run')
              ),
            ),
        ],
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () => 
              WorkflowActions.handleSave(context, ref, saveAs: false),
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true): () => 
              WorkflowActions.handleSave(context, ref, saveAs: true),
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () => 
              WorkflowActions.handleNew(context, ref),
          const SingleActivator(LogicalKeyboardKey.keyO, meta: true): () => 
              WorkflowActions.handleOpen(context, ref),
          const SingleActivator(LogicalKeyboardKey.enter, meta: true): () => 
              WorkflowActions.handleRun(context, ref),
          // Windows/Linux Ctrl mapping (duplicate for safety)
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => 
              WorkflowActions.handleSave(context, ref, saveAs: false),
          const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true): () => 
              WorkflowActions.handleSave(context, ref, saveAs: true),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => 
              WorkflowActions.handleNew(context, ref),
          const SingleActivator(LogicalKeyboardKey.keyO, control: true): () => 
              WorkflowActions.handleOpen(context, ref),
          const SingleActivator(LogicalKeyboardKey.enter, control: true): () => 
              WorkflowActions.handleRun(context, ref),
        },
        child: Column(
          children: [
            // Toolbar
            const WorkflowToolbar(),
            const Divider(height: 1),
            
            Expanded(
              child: Row(
                children: [
                   // Left: Node Palette
                   const SizedBox(
                     width: 250,
                     child: NodePalette(),
                   ),
                   const VerticalDivider(width: 1),
                   
                   // Center: Canvas
                   const Expanded(
                     child: WorkflowCanvas(),
                   ),
                   const VerticalDivider(width: 1),
                   
                   // Right: Inspector
                   const SizedBox(
                     width: 300,
                     child: InspectorPanel(),
                   ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Bottom: Debug Panel
            const SizedBox(
              height: 200, 
              child: DebugPanel(),
            ),
          ],
        ),
      ),
    );
  }
}
