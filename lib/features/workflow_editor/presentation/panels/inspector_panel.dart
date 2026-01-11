import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/workflow_editor_controller.dart';
import '../../domain/models/node_config.dart';
import 'http_node_form.dart';
import 'condition_node_form.dart';
import 'inspector_forms.dart';

class InspectorPanel extends ConsumerWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workflowEditorProvider);
    final selectedId = state.selectedNodeId;
    
    if (selectedId == null) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        alignment: Alignment.center,
        child: const Text('Select a node to edit properties', style: TextStyle(color: Colors.grey)),
      );
    }
    
    final nodeIndex = state.nodes.indexWhere((n) => n.id == selectedId);
    if (nodeIndex == -1) return const SizedBox();
    
    final node = state.nodes[nodeIndex];

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
                Text('Properties: ${node.data['name'] ?? node.type}', style: Theme.of(context).textTheme.titleMedium),
             ],
           ),
           const Divider(),
           
           Expanded(
             child: SingleChildScrollView(
               child: Builder(
                 builder: (context) {
                   // Helper for updates
                   void updateConfig(NodeConfig newConfig) {
                      ref.read(workflowEditorProvider.notifier).updateNodeConfig(node.id, newConfig.toJson());
                   }

                   if (node.type == 'api') {
                     // Existing Http Form (Self-managed mostly but passing nodeId)
                     return HttpNodeForm(
                       key: ValueKey(node.id), 
                       nodeId: node.id, 
                       nodeName: node.data['name'] ?? 'Request',
                       config: node.config is HttpNodeConfig ? node.config as HttpNodeConfig : HttpNodeConfig(url: '', method: 'GET'),
                     );
                   }
                   if (node.type == 'condition') {
                     return ConditionNodeForm(
                       key: ValueKey(node.id),
                       nodeId: node.id,
                       nodeName: node.data['name'] ?? 'Condition',
                       config: node.config is ConditionNodeConfig ? node.config as ConditionNodeConfig : ConditionNodeConfig(expression: ''),
                     );
                   }
                   
                   // WebSocket Forms
                   if (node.type == 'ws_connect') {
                      final config = node.config is WebSocketConnectNodeConfig 
                          ? node.config as WebSocketConnectNodeConfig
                          : WebSocketConnectNodeConfig(url: '');
                      return WebSocketConnectForm(
                        key: ValueKey(node.id),
                        config: config,
                        onSave: updateConfig,
                      );
                   }
                   if (node.type == 'ws_send') {
                      final config = node.config is WebSocketSendNodeConfig
                          ? node.config as WebSocketSendNodeConfig
                          : WebSocketSendNodeConfig(sessionKey: 'mainWs', payload: '');
                      return WebSocketSendForm(
                        key: ValueKey(node.id),
                        config: config,
                        onSave: updateConfig,
                      );
                   }
                   if (node.type == 'ws_wait') {
                      final config = node.config is WebSocketWaitNodeConfig
                          ? node.config as WebSocketWaitNodeConfig
                          : WebSocketWaitNodeConfig(sessionKey: 'mainWs', match: {'type': 'containsText', 'value': ''});
                      return WebSocketWaitForm(
                        key: ValueKey(node.id),
                        config: config,
                        onSave: updateConfig,
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
           ),
        ],
      ),
    );
  }
}
