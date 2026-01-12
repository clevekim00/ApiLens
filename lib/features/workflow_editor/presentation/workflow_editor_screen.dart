import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apilens/features/workflow_editor/application/workflow_editor_controller.dart';
import 'package:apilens/features/execution/application/workflow_runner_controller.dart';
import 'package:apilens/features/workflow_editor/presentation/widgets/workflow_toolbar.dart';
import 'widgets/app_menu_bar.dart'; 
import 'widgets/workflow_actions.dart';
import 'panels/inspector_panel.dart';
import 'panels/node_palette.dart';
import 'panels/debug_panel.dart';
import 'widgets/workflow_canvas.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import '../../../../core/ui/components/app_card.dart';

import '../../workgroup/application/workgroup_controller.dart';
import '../../workflow_editor/data/workflow_repository.dart';

class WorkflowEditorScreen extends ConsumerStatefulWidget {
  final String? workflowIdToLoad;
  const WorkflowEditorScreen({super.key, this.workflowIdToLoad});

  @override
  ConsumerState<WorkflowEditorScreen> createState() => _WorkflowEditorScreenState();
}

class _WorkflowEditorScreenState extends ConsumerState<WorkflowEditorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initWorkflow());
  }

  Future<void> _initWorkflow() async {
    final controller = ref.read(workflowEditorProvider.notifier);
    if (widget.workflowIdToLoad != null) {
       final repo = ref.read(workflowRepositoryProvider);
       // We need a way to get a single workflow. Repository getAll returns list.
       // Let's optimize later, for now filter from all.
       final all = await repo.getAll();
       final wf = all.where((w) => w.id == widget.workflowIdToLoad).firstOrNull;
       if (wf != null) {
         controller.loadWorkflow(wf.id, wf.name, wf.nodes, wf.edges, groupId: wf.groupId);
       }
    } else {
       final activeGroupId = ref.read(activeWorkgroupIdProvider);
       controller.initNewWithGroup(activeGroupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine canvas background based on theme brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasColor = isDark ? AppColorsDark.muted : AppColorsLight.muted;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const AppMenuBar(), 
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.background,
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const WorkflowToolbar(),
                ),
              ),
              const SizedBox(height: 8),
              
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                     // Left: Node Palette
                     const SizedBox(
                       width: 250,
                       child: AppCard(
                         padding: EdgeInsets.zero,
                         child: NodePalette(),
                       ),
                     ),
                     const SizedBox(width: 8),
                     
                     // Center: Canvas
                     Expanded(
                       child: AppCard(
                         padding: EdgeInsets.zero,
                         backgroundColor: canvasColor,
                         child: const ClipRect(child: WorkflowCanvas()),
                       ),
                     ),
                     const SizedBox(width: 8),
                     
                     // Right: InspectorPanel
                     const SizedBox(
                       width: 300,
                       child: AppCard(
                         padding: EdgeInsets.zero,
                         child: InspectorPanel(),
                       ),
                     ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Bottom: Debug Panel
              const SizedBox(
                height: 200, 
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: DebugPanel(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
