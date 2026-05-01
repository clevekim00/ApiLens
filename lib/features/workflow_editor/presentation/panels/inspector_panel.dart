import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/workflow_editor_controller.dart';
import '../../domain/models/node_config.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import 'http_node_form.dart';
import 'condition_node_form.dart';
import 'inspector_forms.dart';
import 'graphql_node_form.dart'; // Add import

class InspectorPanel extends ConsumerWidget {
  const InspectorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workflowEditorProvider);
    final selectedId = state.selectedNodeId;

    if (selectedId == null) {
      return const _InspectorEmptyState();
    }

    final nodeIndex = state.nodes.indexWhere((n) => n.id == selectedId);
    if (nodeIndex == -1) return const SizedBox();

    final node = state.nodes[nodeIndex];
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppTokens.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: AppTokens.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.data['name'] ?? node.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      node.type.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.58),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.s3),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: AppTokens.s3),
          Expanded(
            child: SingleChildScrollView(
              child: Builder(
                builder: (context) {
                  // Helper for updates
                  void updateConfig(NodeConfig newConfig) {
                    ref
                        .read(workflowEditorProvider.notifier)
                        .updateNodeConfig(node.id, newConfig.toJson());
                  }

                  if (node.type == 'api') {
                    // Existing Http Form (Self-managed mostly but passing nodeId)
                    return HttpNodeForm(
                      key: ValueKey(node.id),
                      nodeId: node.id,
                      nodeName: node.data['name'] ?? 'Request',
                      config: node.config is HttpNodeConfig
                          ? node.config as HttpNodeConfig
                          : HttpNodeConfig(url: '', method: 'GET'),
                    );
                  }
                  if (node.type == 'condition') {
                    return ConditionNodeForm(
                      key: ValueKey(node.id),
                      nodeId: node.id,
                      nodeName: node.data['name'] ?? 'Condition',
                      config: node.config is ConditionNodeConfig
                          ? node.config as ConditionNodeConfig
                          : ConditionNodeConfig(expression: ''),
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
                        : WebSocketSendNodeConfig(
                            sessionKey: 'mainWs',
                            payload: '',
                          );
                    return WebSocketSendForm(
                      key: ValueKey(node.id),
                      config: config,
                      onSave: updateConfig,
                    );
                  }

                  if (node.type == 'ws_wait') {
                    final config = node.config is WebSocketWaitNodeConfig
                        ? node.config as WebSocketWaitNodeConfig
                        : WebSocketWaitNodeConfig(
                            sessionKey: 'mainWs',
                            match: {'type': 'containsText', 'value': ''},
                          );
                    return WebSocketWaitForm(
                      key: ValueKey(node.id),
                      config: config,
                      onSave: updateConfig,
                    );
                  }

                  // GraphQL Form
                  if (node.type == 'gql_request') {
                    final config = node.config is GraphQLNodeConfig
                        ? node.config as GraphQLNodeConfig
                        : GraphQLNodeConfig();
                    return GraphQLNodeForm(
                      key: ValueKey(node.id),
                      nodeId: node.id,
                      config: config,
                      onSave: updateConfig,
                    );
                  }

                  return _GenericNodeState(type: node.type);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorEmptyState extends StatelessWidget {
  const _InspectorEmptyState();

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
              Icons.ads_click_outlined,
              size: 34,
              color: theme.colorScheme.primary.withValues(alpha: 0.62),
            ),
            const SizedBox(height: AppTokens.s3),
            Text(
              'Select a node',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTokens.s1),
            Text(
              'Node properties and configuration will appear here.',
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

class _GenericNodeState extends StatelessWidget {
  final String type;

  const _GenericNodeState({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.035),
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      child: Text(
        'No specific properties for "$type".',
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
