import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apilens/features/workflow_editor/application/workflow_editor_controller.dart';
import 'package:apilens/features/workflow_editor/presentation/widgets/workflow_toolbar.dart';
import 'widgets/app_menu_bar.dart';
import 'widgets/workflow_actions.dart';
import 'panels/inspector_panel.dart';
import 'panels/node_palette.dart';
import 'panels/debug_panel.dart';
import 'widgets/workflow_canvas.dart';
import '../../../../core/ui/tokens/app_tokens.dart';

import '../../workgroup/application/workgroup_controller.dart';
import '../../workflow_editor/data/workflow_repository.dart';

class WorkflowEditorScreen extends ConsumerStatefulWidget {
  final String? workflowIdToLoad;
  const WorkflowEditorScreen({super.key, this.workflowIdToLoad});

  @override
  ConsumerState<WorkflowEditorScreen> createState() =>
      _WorkflowEditorScreenState();
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
      final all = await repo.getAll();
      if (!mounted) return;

      final wf = all.where((w) => w.id == widget.workflowIdToLoad).firstOrNull;

      if (wf != null) {
        controller.loadWorkflow(wf.id, wf.name, wf.nodes, wf.edges,
            groupId: wf.groupId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workflow not found')),
        );
      }
    } else {
      final activeGroupId = ref.read(activeWorkgroupIdProvider);
      controller.initNewWithGroup(activeGroupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine canvas background based on theme brightness
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canvasColor = isDark ? AppColorsDark.muted : AppColorsLight.muted;

    return Scaffold(
      backgroundColor: _workspaceBackground(context),
      appBar: AppBar(
        title: const AppMenuBar(),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
              WorkflowActions.handleSave(context, ref, saveAs: false),
          const SingleActivator(LogicalKeyboardKey.keyS,
                  meta: true, shift: true):
              () => WorkflowActions.handleSave(context, ref, saveAs: true),
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
              WorkflowActions.handleNew(context, ref),
          const SingleActivator(LogicalKeyboardKey.keyO, meta: true): () =>
              WorkflowActions.handleOpen(context, ref),
          const SingleActivator(LogicalKeyboardKey.enter, meta: true): () =>
              WorkflowActions.handleRun(context, ref),
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
              WorkflowActions.handleSave(context, ref, saveAs: false),
          const SingleActivator(LogicalKeyboardKey.keyS,
                  control: true, shift: true):
              () => WorkflowActions.handleSave(context, ref, saveAs: true),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
              WorkflowActions.handleNew(context, ref),
          const SingleActivator(LogicalKeyboardKey.keyO, control: true): () =>
              WorkflowActions.handleOpen(context, ref),
          const SingleActivator(LogicalKeyboardKey.enter, control: true): () =>
              WorkflowActions.handleRun(context, ref),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1040;
            final compactToolsHeight =
                constraints.maxHeight < 720 ? 220.0 : 260.0;

            return Padding(
              padding: const EdgeInsets.all(AppTokens.s3),
              child: Column(
                children: [
                  const SizedBox(
                    height: 42,
                    child: _WorkflowPanel(child: WorkflowToolbar()),
                  ),
                  const SizedBox(height: AppTokens.s3),
                  if (compact) ...[
                    Expanded(
                      child: _WorkflowCanvasPanel(canvasColor: canvasColor),
                    ),
                    const SizedBox(height: AppTokens.s3),
                    SizedBox(
                      height: compactToolsHeight,
                      child: const _WorkflowPanel(
                        child: _CompactWorkflowTools(),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(
                            width: 260,
                            child: _WorkflowPanel(child: NodePalette()),
                          ),
                          const SizedBox(width: AppTokens.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _WorkflowCanvasPanel(
                                    canvasColor: canvasColor,
                                  ),
                                ),
                                const SizedBox(height: AppTokens.s3),
                                const SizedBox(
                                  height: 200,
                                  child: _WorkflowPanel(child: DebugPanel()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTokens.s3),
                          const SizedBox(
                            width: 300,
                            child: _WorkflowPanel(child: InspectorPanel()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorkflowCanvasPanel extends StatelessWidget {
  final Color canvasColor;

  const _WorkflowCanvasPanel({required this.canvasColor});

  @override
  Widget build(BuildContext context) {
    return _WorkflowPanel(
      backgroundColor: canvasColor,
      child: const ClipRect(
        key: Key('canvas_workflow'),
        child: WorkflowCanvas(),
      ),
    );
  }
}

class _CompactWorkflowTools extends StatelessWidget {
  const _CompactWorkflowTools();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            height: 38,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.62),
              tabs: const [
                Tab(
                    icon: Icon(Icons.widgets_outlined, size: 16),
                    text: 'Nodes'),
                Tab(icon: Icon(Icons.tune, size: 16), text: 'Inspector'),
                Tab(
                    icon: Icon(Icons.bug_report_outlined, size: 16),
                    text: 'Debug'),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          const Expanded(
            child: TabBarView(
              children: [
                NodePalette(),
                InspectorPanel(),
                DebugPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowPanel extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;

  const _WorkflowPanel({
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : const [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        child: child,
      ),
    );
  }
}

Color _workspaceBackground(BuildContext context) {
  final theme = Theme.of(context);
  return Color.alphaBlend(
    theme.colorScheme.primary.withValues(alpha: 0.025),
    theme.scaffoldBackgroundColor,
  );
}
