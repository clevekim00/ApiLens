import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:apilens/features/workgroup/application/workgroup_controller.dart';
import 'package:apilens/features/workgroup/application/workgroup_export_service.dart';
import 'package:apilens/features/workgroup/domain/models/workgroup_model.dart';
import 'package:apilens/features/request/application/saved_request_controller.dart';
import 'package:apilens/features/request/providers/request_provider.dart';
import 'package:apilens/features/workflow_editor/application/saved_workflow_controller.dart';
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
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo((_scrollController.offset - scrollStep).clamp(0.0, _scrollController.position.maxScrollExtent));
        }
      });
    } else if (position.dy > height - threshold) {
      // Scroll Down
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo((_scrollController.offset + scrollStep).clamp(0.0, _scrollController.position.maxScrollExtent));
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
        // Toolbar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text('Explorer', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.create_new_folder, size: 20),
                onPressed: () => _showCreateFolderDialog(context),
                tooltip: 'New Folder',
              ),
              IconButton(
                icon: const Icon(Icons.upload_file, size: 20),
                onPressed: () => _importWorkgroup(context),
                tooltip: 'Import Workgroup',
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
                   color: candidates.isNotEmpty ? Colors.blue.withOpacity(0.1) : null,
                   child: ListView(
                    controller: _scrollController,
                    children: [
                      ...topLevelGroups.map((folder) => _FolderTile(folder: folder)),
                    ],
                   ),
                 ),
               );
            },
            onWillAccept: (data) => true,
            onAccept: (requestId) {
               _stopAutoScroll();
               // Move to System Default ('no-workgroup')
               ref.read(savedRequestControllerProvider.notifier).moveRequest(requestId, 'no-workgroup');
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moved to No Workgroup')));
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(workgroupControllerProvider.notifier).createGroup(
                  controller.text, 
                  WorkgroupType.requestCollection
                );
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
        withData: true, // Required for Web access to bytes
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
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import Successful')));
        }
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }
}


Future<void> _showSwaggerImportDialog(BuildContext context, WidgetRef ref, String targetGroupId) async {
  await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OpenApiImportScreen(targetGroupId: targetGroupId)),
  );
}

class _FolderTile extends ConsumerWidget {
  final WorkgroupModel folder;
  
  const _FolderTile({required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get children folders
    final childrenFolders = ref.watch(folderChildrenProvider(folder.id));
    // Get children requests
    final allRequests = ref.watch(savedRequestControllerProvider);
    final childrenRequests = allRequests.where((r) => r.groupId == folder.id).toList();

    // Get children workflows
    final allWorkflows = ref.watch(savedWorkflowControllerProvider);
    final childrenWorkflows = allWorkflows.where((w) => w.groupId == folder.id).toList();

    return DragTarget<String>(
      builder: (context, candidates, rejects) {
        return ExpansionTile(
          initiallyExpanded: folder.isSystem, // Auto expand system group
          leading: Icon(
             folder.isSystem ? Icons.archive : Icons.folder, // Distinct icon for system
             size: 18, 
             color: candidates.isNotEmpty ? Colors.blue : (folder.isSystem ? Colors.orangeAccent : Colors.blueGrey)
          ),
          title: Text(folder.name, style: TextStyle(
            fontSize: 13, 
            fontWeight: folder.isSystem ? FontWeight.w600 : FontWeight.normal
          )),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 16),
            itemBuilder: (_) => [
              const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
              const PopupMenuItem<String>(value: 'export_json', child: Text('Export JSON')),
              if (!folder.isSystem) ...[
                const PopupMenuItem<String>(value: 'rename', child: Text('Rename')),
                const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
              ]
            ],
            onSelected: (value) async {
              if (value == 'delete') {
                 _showDeleteDialog(context, ref);
              } else if (value == 'rename') {
                 _showRenameDialog(context, ref);
              } else if (value == 'export_json') {
                 try {
                   final jsonString = await ref.read(workgroupExportServiceProvider).exportWorkgroup(folder.id);
                   
                   // Desktop Save Dialog
                   String? outputFile = await FilePicker.platform.saveFile(
                     dialogTitle: 'Export Workgroup',
                     fileName: '${folder.name}.apilens-workgroup.json',
                     type: FileType.custom,
                     allowedExtensions: ['json'],
                   );

                   if (outputFile != null) {
                      final file = File(outputFile);
                      await file.writeAsString(jsonString);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $outputFile')));
                   } else {
                      // User canceled
                   }
                 } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red));
                 }
              } else if (value == 'import_swagger') {
                 _showSwaggerImportDialog(context, ref, folder.id);
              }
            },
          ),
          childrenPadding: const EdgeInsets.only(left: 16),
          children: [
            ...childrenFolders.map((subFolder) => _FolderTile(folder: subFolder)),
            ...childrenRequests.map((req) => _RequestTile(req: req)),
            ...childrenWorkflows.map((w) => _WorkflowTile(workflow: w)),
          ],
        );
      },
      onWillAccept: (requestId) => requestId != null, 
      onAccept: (requestId) {
        if (requestId.isNotEmpty) {
           // We might need to differentiate between request and workflow logic later if dragging workflows is supported
           // For now assume string is requestId, but if we support workflow drag we need type or prefix
           ref.read(savedRequestControllerProvider.notifier).moveRequest(requestId, folder.id);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Moved to ${folder.name}')));
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
             onPressed: () {
               if (controller.text.isNotEmpty) {
                 ref.read(workgroupControllerProvider.notifier).updateGroup(folder.id, name: controller.text);
                 Navigator.pop(context);
               }
             },
             child: const Text('Rename'),
          )
        ],
      )
    );
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
                 title: const Text('Move contents to "No Workgroup" (Safe)'),
                 subtitle: const Text('Uncheck to permanently delete contents'),
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
              child: const Text('Cancel')
            ),
            TextButton(
              onPressed: () {
                 ref.read(workgroupControllerProvider.notifier).deleteGroup(folder.id, moveToSystem: moveToSystem);
                 Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red))
            ),
          ],
        ),
      )
    );
  }

}

// ... (existing imports)

class _DragPreview extends StatelessWidget {
  final String text;
  final IconData icon;
  
  const _DragPreview({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Opacity(
        opacity: 0.85,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestTile extends ConsumerWidget {
  final dynamic req; // details
  
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
    return ListTile(
      leading: const Icon(Icons.http, size: 16),
      title: Text(req.name, style: const TextStyle(fontSize: 13)),
      onTap: () {
        ref.read(requestNotifierProvider.notifier).restoreRequest(req);
      },
      dense: true,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 16),
        itemBuilder: (_) => [
          const PopupMenuItem<String>(value: 'move_root', child: Text('Move to No Workgroup')),
          const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
        ],
        onSelected: (value) {
          if (value == 'move_root') {
            ref.read(savedRequestControllerProvider.notifier).moveRequest(req.id, 'no-workgroup');
          } else if (value == 'delete') {
            ref.read(savedRequestControllerProvider.notifier).deleteRequest(req.id);
          }
        },
      ),
    );
  }
}

class _WorkflowTile extends ConsumerWidget {
  final dynamic workflow;
  
  const _WorkflowTile({required this.workflow});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.account_tree_outlined, size: 16, color: Colors.purple),
      title: Text(workflow.name, style: const TextStyle(fontSize: 13)),
      onTap: () {
         Navigator.push(context, MaterialPageRoute(
            builder: (_) => WorkflowEditorScreen(workflowIdToLoad: workflow.id)
         ));
      },
      dense: true,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 16),
        itemBuilder: (_) => [
          const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
        ],
        onSelected: (value) {
          if (value == 'delete') {
             ref.read(savedWorkflowControllerProvider.notifier).deleteWorkflow(workflow.id);
          }
        },
      ),
    );
  }
}
