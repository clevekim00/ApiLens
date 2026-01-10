import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/workflow_editor_controller.dart';
import '../../domain/models/node_config.dart';
import 'http_node_form.dart';
import 'condition_node_form.dart';

class InspectorPanel extends ConsumerWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workflowEditorProvider);
    final selectedId = state.selectedNodeId;
    
    // Ensure we have a valid selection
    if (selectedId == null) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        alignment: Alignment.center,
        child: const Text('Select a node to edit properties', style: TextStyle(color: Colors.grey)),
      );
    }
    
    // Find node safely
    final nodeIndex = state.nodes.indexWhere((n) => n.id == selectedId);
    if (nodeIndex == -1) return const SizedBox();
    
    final node = state.nodes[nodeIndex];
    final nodeName = node.data['name'] ?? node.type;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
                Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Properties', style: Theme.of(context).textTheme.titleMedium),
             ],
           ),
           const Divider(),
           
           Expanded(
             child: Builder(
               builder: (context) {
                 if (node.type == 'api') {
                   // Ensure config is HttpNodeConfig, or create default if matching failed (unlikely if created via palette)
                   // But beware of state updates causing rebuilds. Forms usually need unique keys if node changes.
                   // We use Key(selectedId) to force rebuild form when selection changes.
                   HttpNodeConfig config;
                   try {
                      config = node.config as HttpNodeConfig;
                   } catch (_) {
                      config = HttpNodeConfig(url: '', method: 'GET'); // Fallback
                   }
                   return HttpNodeForm(
                     key: ValueKey(node.id), 
                     nodeId: node.id, 
                     nodeName: nodeName,
                     config: config,
                   );
                 }
                 
                 if (node.type == 'condition') {
                   ConditionNodeConfig config;
                   try {
                     config = node.config as ConditionNodeConfig;
                   } catch (_) {
                     config = ConditionNodeConfig(expression: '');
                   }
                   return ConditionNodeForm(
                     key: ValueKey(node.id),
                     nodeId: node.id,
                     nodeName: nodeName,
                     config: config,
                   );
                 }
                 
                 return Column(
                   children: [
                     Text('Type: ${node.type}'),
                     const Text('No specific properties for this node type.'),
                   ],
                 );
               },
             ),
           ),
        ],
      ),
    );
  }
}
