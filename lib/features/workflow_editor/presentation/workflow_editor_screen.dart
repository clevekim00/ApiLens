import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apilens/features/workflow_editor/application/workflow_editor_controller.dart';
import 'package:apilens/features/execution/application/workflow_runner_controller.dart';
import 'package:apilens/features/execution/presentation/widgets/execution_controls.dart';
import 'package:apilens/features/workflow_editor/presentation/widgets/workflow_toolbar.dart';
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
        title: const Text('Workflow Editor'),
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
      body: Column(
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
            height: 200, // Increased height for better visibility of context
            child: DebugPanel(),
          ),
        ],
      ),
    );
  }
}
