import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:apilens/core/ui/tokens/app_tokens.dart';
import 'package:apilens/features/workgroup/application/workgroup_controller.dart';
import 'package:apilens/features/workgroup/application/workgroup_export_service.dart';
import 'package:apilens/features/workgroup/domain/models/workgroup_model.dart';
import 'package:apilens/features/request/application/saved_request_controller.dart';
import 'package:apilens/features/request/models/request_model.dart';
import 'package:apilens/features/request/providers/request_provider.dart';
import 'package:apilens/features/workflow_editor/application/saved_workflow_controller.dart';
import 'package:apilens/features/workflow_editor/domain/models/workflow.dart';
import 'package:apilens/features/workflow_editor/presentation/workflow_editor_screen.dart';
import 'package:apilens/features/import/presentation/screens/openapi_import_screen.dart';

class WorkgroupExplorer extends ConsumerStatefulWidget {
  const WorkgroupExplorer({super.key});

  @override
  ConsumerState<WorkgroupExplorer> createState() => _WorkgroupExplorerState();
}

class _WorkgroupExplorerState extends ConsumerState<WorkgroupExplorer> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;

  @override
  void dispose() {
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _checkAutoScroll(Offset position, double height) {
    const double threshold = 50.0;
    const double scrollStep = 10.0;

    _autoScrollTimer?.cancel();

    if (position.dy < threshold) {
      // Scroll Up
      _autoScrollTimer =
          Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo((_scrollController.offset - scrollStep)
              .clamp(0.0, _scrollController.position.maxScrollExtent));
        }
      });
    } else if (position.dy > height - threshold) {
      // Scroll Down
      _autoScrollTimer =
          Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo((_scrollController.offset + scrollStep)
              .clamp(0.0, _scrollController.position.maxScrollExtent));
        }
      });
    }
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine root folders (parentId == null OR parentId == 'no-workgroup')
    // Wait, the new logic is:
    // - Everything MUST be in a group.
    // - 'no-workgroup' is the default catch-all.
    // - 'no-workgroup' has parentId = null.
    // - Other Root folders have parentId = null? Or are they children of no-workgroup?
    // - Usually "My Collections" are peers of "No Workgroup" (System).
    // - So we list ALL groups with parentId == null.

    final allGroups = ref.watch(workgroupControllerProvider);
    final topLevelGroups = allGroups.where((g) => g.parentId == null).toList();

    // Requests shouldn't be loose anymore (migration will fix this).
    // But if any are loose (legacy), maybe show them or ignore?
    // Let's assume migration logic runs on app start.

    // Sort: System group first, then others
    topLevelGroups.sort((a, b) {
      if (a.isSystem) return -1;
      if (b.isSystem) return 1;
      return a.name.compareTo(b.name);
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s3,
            vertical: AppTokens.s2,
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_shared_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTokens.s2),
              Expanded(
                child: Text(
                  'Workgroup Explorer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _ExplorerCountBadge(count: topLevelGroups.length),
              const SizedBox(width: AppTokens.s1),
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                onPressed: () => _showCreateFolderDialog(context),
                tooltip: 'New Folder',
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.import_export_rounded, size: 18),
                onPressed: () => _importWorkgroup(context),
                tooltip: 'Import Workgroup',
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: DragTarget<String>(
            builder: (context, candidates, rejects) {
              return Listener(
                onPointerMove: (event) {
                  if (context.size != null) {
                    _checkAutoScroll(event.localPosition, context.size!.height);
                  }
                },
                onPointerUp: (_) => _stopAutoScroll(),
                onPointerCancel: (_) => _stopAutoScroll(),
                child: Container(
                  color: candidates.isNotEmpty
                      ? theme.colorScheme.primary.withValues(alpha: 0.10)
                      : null,
                  child: topLevelGroups.isEmpty
                      ? const _ExplorerEmptyState()
                      : ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTokens.s2,
                          ),
                          children: [
                            ...topLevelGroups
                                .map((folder) => _FolderTile(folder: folder)),
                          ],
                        ),
                ),
              );
            },
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (details) {
              _stopAutoScroll();
              ref
                  .read(savedRequestControllerProvider.notifier)
                  .moveRequest(details.data, 'no-workgroup');
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Moved to No Workgroup')));
            },
            onLeave: (_) => _stopAutoScroll(),
          ),
        ),
      ],
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(workgroupControllerProvider.notifier).createGroup(
                    controller.text, WorkgroupType.requestCollection);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _importWorkgroup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        String content;

        if (file.bytes != null) {
          content = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          final ioFile = File(file.path!);
          content = await ioFile.readAsString();
        } else {
          throw Exception('Cannot read file content');
        }

        await ref.read(workgroupExportServiceProvider).importWorkgroup(content);

        ref.invalidate(workgroupControllerProvider);
        ref.invalidate(savedRequestControllerProvider);
        ref.invalidate(savedWorkflowControllerProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Import Successful')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Import Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

Future<void> _showSwaggerImportDialog(
    BuildContext context, WidgetRef ref, String targetGroupId) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => OpenApiImportScreen(targetGroupId: targetGroupId)),
  );
}

class _FolderTile extends ConsumerWidget {
  final WorkgroupModel folder;

  const _FolderTile({required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final childrenFolders = ref.watch(folderChildrenProvider(folder.id));
    final allRequests = ref.watch(savedRequestControllerProvider);
    final childrenRequests =
        allRequests.where((r) => r.groupId == folder.id).toList();
    final allWorkflows = ref.watch(savedWorkflowControllerProvider);
    final childrenWorkflows =
        allWorkflows.where((w) => w.groupId == folder.id).toList();
    final childCount = childrenFolders.length +
        childrenRequests.length +
        childrenWorkflows.length;

    return DragTarget<String>(
      builder: (context, candidates, rejects) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTokens.s1),
          decoration: BoxDecoration(
            color: candidates.isNotEmpty
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : null,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: ExpansionTile(
            initiallyExpanded: folder.isSystem,
            tilePadding: const EdgeInsets.only(left: AppTokens.s2, right: 2),
            childrenPadding: const EdgeInsets.only(left: AppTokens.s3),
            visualDensity: VisualDensity.compact,
            shape: const Border(),
            collapsedShape: const Border(),
            leading: Icon(
              Icons.folder_rounded,
              size: 18,
              color: folder.isSystem
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.primary.withValues(alpha: 0.80),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (childCount > 0) ...[
                  const SizedBox(width: AppTokens.s1),
                  _ExplorerCountBadge(count: childCount),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded, size: 16),
              padding: EdgeInsets.zero,
              splashRadius: 16,
              itemBuilder: (_) => [
                const PopupMenuItem<String>(
                    value: 'new_workflow', child: Text('New Workflow')),
                const PopupMenuItem<String>(
                    value: 'import_swagger',
                    child: Text('New Workflow from Swagger')),
                const PopupMenuItem<String>(
                    value: 'export_json', child: Text('Export JSON')),
                if (!folder.isSystem) ...[
                  const PopupMenuItem<String>(
                      value: 'rename', child: Text('Rename')),
                  const PopupMenuItem<String>(
                      value: 'delete', child: Text('Delete')),
                ] else ...[
                  const PopupMenuItem<String>(
                      value: 'delete', child: Text('Delete')),
                ]
              ],
              onSelected: (value) async {
                if (value == 'delete') {
                  _showDeleteDialog(context, ref);
                } else if (value == 'rename') {
                  _showRenameDialog(context, ref);
                } else if (value == 'export_json') {
                  try {
                    final jsonString = await ref
                        .read(workgroupExportServiceProvider)
                        .exportWorkgroup(folder.id);
                    String? outputFile = await FilePicker.platform.saveFile(
                      dialogTitle: 'Export Workgroup',
                      fileName: '${folder.name}.apilens-workgroup.json',
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );

                    if (outputFile != null) {
                      final file = File(outputFile);
                      await file.writeAsString(jsonString);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Saved to $outputFile')));
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Export Failed: $e'),
                          backgroundColor: Colors.red));
                    }
                  }
                } else if (value == 'new_workflow') {
                  _showCreateWorkflowDialog(context, ref, folder.id);
                } else if (value == 'import_swagger') {
                  _showSwaggerImportDialog(context, ref, folder.id);
                }
              },
            ),
            children: [
              ...childrenFolders
                  .map((subFolder) => _FolderTile(folder: subFolder)),
              ...childrenRequests.map((req) => _RequestTile(req: req)),
              ...childrenWorkflows.map((w) => _WorkflowTile(workflow: w)),
            ],
          ),
        );
      },
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final requestId = details.data;
        if (requestId.isNotEmpty) {
          ref
              .read(savedRequestControllerProvider.notifier)
              .moveRequest(requestId, folder.id);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Moved to ${folder.name}')));
        }
      },
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Rename Folder'),
              content: TextField(controller: controller, autofocus: true),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      ref
                          .read(workgroupControllerProvider.notifier)
                          .updateGroup(folder.id, name: controller.text);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Rename'),
                )
              ],
            ));
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    bool moveToSystem = true;
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text('Delete Folder'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Are you sure you want to delete this folder?'),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title:
                          const Text('Move contents to "No Workgroup" (Safe)'),
                      subtitle:
                          const Text('Uncheck to permanently delete contents'),
                      value: moveToSystem,
                      onChanged: (val) => setState(() => moveToSystem = val!),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    )
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () {
                        ref
                            .read(workgroupControllerProvider.notifier)
                            .deleteGroup(folder.id, moveToSystem: moveToSystem);
                        Navigator.pop(context);
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            ));
  }
}

void _showCreateWorkflowDialog(
    BuildContext context, WidgetRef ref, String targetGroupId) {
  final controller = TextEditingController(text: 'New Workflow');
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('New Workflow'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Name'),
        autofocus: true,
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (controller.text.isNotEmpty) {
              final id = await ref
                  .read(savedWorkflowControllerProvider.notifier)
                  .createWorkflow(
                      name: controller.text, groupId: targetGroupId);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            WorkflowEditorScreen(workflowIdToLoad: id)));
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

class _DragPreview extends StatelessWidget {
  final String text;
  final IconData icon;

  const _DragPreview({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.85,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s3,
            vertical: AppTokens.s2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: AppTokens.s2),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestTile extends ConsumerWidget {
  final RequestModel req;

  const _RequestTile({required this.req});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Draggable<String>(
      data: req.id,
      feedback: _DragPreview(text: req.name, icon: Icons.http),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildTile(context, ref)),
      child: _buildTile(context, ref),
    );
  }

  Widget _buildTile(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return _ExplorerLeafTile(
      icon: Icons.http,
      iconColor: _methodColor(req.method),
      title: req.name,
      subtitle: req.url.isEmpty ? 'No URL' : req.url,
      leadingLabel: req.method,
      leadingColor: _methodColor(req.method),
      onTap: () {
        ref.read(requestNotifierProvider.notifier).restoreRequest(req);
      },
      trailing: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: theme.iconTheme.color,
        ),
        padding: EdgeInsets.zero,
        splashRadius: 16,
        itemBuilder: (_) => [
          const PopupMenuItem<String>(
              value: 'move_root', child: Text('Move to No Workgroup')),
          const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
        ],
        onSelected: (value) {
          if (value == 'move_root') {
            ref
                .read(savedRequestControllerProvider.notifier)
                .moveRequest(req.id, 'no-workgroup');
          } else if (value == 'delete') {
            ref
                .read(savedRequestControllerProvider.notifier)
                .deleteRequest(req.id);
          }
        },
      ),
    );
  }
}

class _WorkflowTile extends ConsumerWidget {
  final Workflow workflow;

  const _WorkflowTile({required this.workflow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return _ExplorerLeafTile(
      icon: Icons.account_tree_outlined,
      iconColor: theme.colorScheme.primary.withValues(alpha: 0.70),
      title: workflow.name,
      subtitle:
          '${workflow.nodes.length} nodes / ${workflow.edges.length} edges',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkflowEditorScreen(workflowIdToLoad: workflow.id),
          ),
        );
      },
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded, size: 14),
        onPressed: () => ref
            .read(savedWorkflowControllerProvider.notifier)
            .deleteWorkflow(workflow.id),
        padding: EdgeInsets.zero,
        splashRadius: 16,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(
          width: 28,
          height: 28,
        ),
      ),
    );
  }
}

class _ExplorerLeafTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? leadingLabel;
  final Color? leadingColor;
  final VoidCallback onTap;
  final Widget trailing;

  const _ExplorerLeafTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    required this.trailing,
    this.subtitle,
    this.leadingLabel,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppTokens.s1,
        right: AppTokens.s1,
        bottom: AppTokens.s1,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s2,
              AppTokens.s1,
              AppTokens.s1,
              AppTokens.s1,
            ),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                theme.colorScheme.primary.withValues(alpha: 0.018),
                theme.colorScheme.surface,
              ),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: AppTokens.s2),
                if (leadingLabel != null && leadingColor != null) ...[
                  _MiniMethodBadge(label: leadingLabel!, color: leadingColor!),
                  const SizedBox(width: AppTokens.s2),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.56),
                          ),
                        ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniMethodBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniMethodBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _ExplorerCountBadge extends StatelessWidget {
  final int count;

  const _ExplorerCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ExplorerEmptyState extends StatelessWidget {
  const _ExplorerEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.create_new_folder_outlined,
              size: 30,
              color: theme.colorScheme.primary.withValues(alpha: 0.62),
            ),
            const SizedBox(height: AppTokens.s2),
            Text(
              'No workgroups',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTokens.s1),
            Text(
              'Create a folder to organize requests and workflows.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _methodColor(String method) {
  switch (method.toUpperCase()) {
    case 'GET':
      return Colors.blue;
    case 'POST':
      return Colors.green;
    case 'PUT':
      return Colors.orange;
    case 'DELETE':
      return Colors.redAccent;
    case 'PATCH':
      return Colors.purpleAccent;
    default:
      return Colors.blueGrey;
  }
}
