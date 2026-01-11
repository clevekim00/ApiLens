import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/workflow_editor_controller.dart';
import '../../data/workflow_repository.dart';
import '../../domain/models/workflow.dart';
import 'workflow_actions.dart'; // Add this import

import '../../data/sample_workflows.dart';

class WorkflowToolbar extends ConsumerWidget {
  const WorkflowToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workflowEditorProvider);
    final repo = ref.read(workflowRepositoryProvider);
    final notifier = ref.read(workflowEditorProvider.notifier);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          // Name Editor
          SizedBox(
            width: 200,
            child: TextField(
              controller: TextEditingController(text: state.name)
                ..selection = TextSelection.fromPosition(TextPosition(offset: state.name.length)),
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Workflow Name'),
              style: const TextStyle(fontWeight: FontWeight.bold),
              onSubmitted: (val) => notifier.updateName(val),
            ),
          ),
          const Spacer(),
          
          // Actions
          TextButton.icon(
            icon: const Icon(Icons.science_outlined, size: 16),
            label: const Text('Samples'),
            onPressed: () {
              showDialog(context: context, builder: (ctx) => SimpleDialog(
                title: const Text('Load Sample Workflow'),
                children: SampleWorkflows.samples.map((wf) => SimpleDialogOption(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8), 
                    child: Text(wf.name, style: const TextStyle(fontSize: 16)),
                  ),
                  onPressed: () {
                    notifier.loadWorkflow(wf.id, wf.name, wf.nodes, wf.edges);
                    Navigator.pop(ctx);
                  },
                )).toList(),
              ));
            },
          ),
          const VerticalDivider(indent: 10, endIndent: 10),
          IconButton(
            tooltip: 'New Workflow',
            icon: const Icon(Icons.add),
            onPressed: () {
               // Confirm if dirty? For MVP just clear.
               notifier.clearWorkflow();
            },
          ),
          IconButton(
            tooltip: 'Open Saved',
            icon: const Icon(Icons.folder_open),
            onPressed: () async {
              final workflows = await repo.getAll();
              if (context.mounted) {
                showDialog(
                  context: context, 
                  builder: (ctx) => WorkflowListDialog(workflows: workflows, onLoad: (wf) {
                    notifier.loadWorkflow(wf.id, wf.name, wf.nodes, wf.edges);
                    Navigator.of(ctx).pop();
                  }, onDelete: (id) async {
                     await repo.delete(id);
                     Navigator.of(ctx).pop(); // Refresh needed? Ideally rebuild dialog or use Stateful
                  })
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Run Workflow',
            icon: const Icon(Icons.play_arrow, color: Colors.green),
            onPressed: () => WorkflowActions.handleRun(context, ref),
          ),
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save),
            onPressed: () async {
               final wf = Workflow(
                 id: state.id,
                 name: state.name,
                 nodes: state.nodes,
                 edges: state.edges,
                 lastModified: DateTime.now(),
               );
               await repo.save(wf);
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workflow Saved!')));
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) async {
               if (val == 'export') {
                  final wf = Workflow(
                     id: state.id,
                     name: state.name,
                     nodes: state.nodes,
                     edges: state.edges,
                   );
                  final json = repo.exportJson(wf);
                  // Clipboard
                  Clipboard.setData(ClipboardData(text: json));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON copied to clipboard')));
               } else if (val == 'import') {
                   // Show import dialog
                   showDialog(context: context, builder: (ctx) => ImportWorkflowDialog(onImport: (json) {
                      try {
                        final wf = repo.importJson(json);
                        notifier.loadWorkflow(wf.id, wf.name, wf.nodes, wf.edges);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workflow Imported!')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                   }));
               }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'export', child: Text('Export JSON')),
              const PopupMenuItem(value: 'import', child: Text('Import JSON')),
            ],
          )
        ],
      ),
    );
  }
}

class WorkflowListDialog extends StatelessWidget {
  final List<Workflow> workflows;
  final Function(Workflow) onLoad;
  final Function(String) onDelete;

  const WorkflowListDialog({super.key, required this.workflows, required this.onLoad, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Saved Workflows'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: workflows.isEmpty 
           ? const Center(child: Text('No saved workflows'))
           : ListView.builder(
             itemCount: workflows.length,
             itemBuilder: (ctx, i) {
                final wf = workflows[i];
                return ListTile(
                  title: Text(wf.name),
                  subtitle: Text(wf.lastModified?.toString().substring(0, 16) ?? '-'),
                  onTap: () => onLoad(wf),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => onDelete(wf.id),
                  ),
                );
             },
           ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}

class SimpleDialogItem extends StatelessWidget {
  const SimpleDialogItem({super.key, required this.icon, required this.color, required this.text, required this.onPressed});

  final IconData? icon;
  final Color? color;
  final String text;
  final VoidCallback onPressed;

  // Simplified constructor for this use case
  SimpleDialogItem.forSample({super.key, required this.text, required this.onPressed}) : icon = Icons.account_tree, color = null;
  
  // Actually, standard constructor:
  const SimpleDialogItem.standard({super.key, required this.text, required this.onPressed}) : icon = null, color = null;


  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          if (icon != null) ...[Icon(icon, size: 36.0, color: color), const Padding(padding: EdgeInsets.only(left: 16.0))],
          Text(text),
        ],
      ),
    );
  }
}
class ImportWorkflowDialog extends StatefulWidget {
  final Function(String) onImport;
  const ImportWorkflowDialog({super.key, required this.onImport});
  
  @override
  State<ImportWorkflowDialog> createState() => _ImportWorkflowDialogState();
}

class _ImportWorkflowDialogState extends State<ImportWorkflowDialog> {
  final _controller = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import JSON'),
      content: SizedBox(
        width: 400,
        child: TextField(
          controller: _controller,
          maxLines: 10,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Paste JSON here...'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => widget.onImport(_controller.text), child: const Text('Import')),
      ],
    );
  }
}
