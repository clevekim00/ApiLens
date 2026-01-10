import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../application/workflow_editor_controller.dart';
import '../../domain/models/workflow_node.dart';

class NodePalette extends ConsumerWidget {
  const NodePalette({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Nodes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildDraggableItem(context, ref, 'API Request', 'api', Icons.api, Colors.blue),
                _buildDraggableItem(context, ref, 'Condition', 'condition', Icons.call_split, Colors.orange),
                _buildDraggableItem(context, ref, 'Start', 'start', Icons.play_arrow, Colors.green),
                _buildDraggableItem(context, ref, 'End', 'end', Icons.stop, Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableItem(BuildContext context, WidgetRef ref, String label, String type, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // Quick add for testing
        final id = const Uuid().v4();
        ref.read(workflowEditorProvider.notifier).addNode(
           WorkflowNode(id: id, type: type, x: 100, y: 100, data: {'name': label})
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
