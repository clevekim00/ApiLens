import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/websocket_config.dart';
import '../../domain/models/websocket_message.dart'; // For status badging if needed
import '../../application/websocket_controller.dart';
import '../../data/websocket_config_repository.dart';
import '../widgets/websocket_client_panel.dart';

class WebSocketClientScreen extends ConsumerStatefulWidget {
  const WebSocketClientScreen({super.key});

  @override
  ConsumerState<WebSocketClientScreen> createState() => _WebSocketClientScreenState();
}

class _WebSocketClientScreenState extends ConsumerState<WebSocketClientScreen> {
  // Config List is specific to this screen
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(webSocketClientProvider);
    final configsAsync = ref.watch(websocketConfigsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Client'),
        actions: [
           // Status Badge
           _ConnectionStatusBadge(status: state.session.status),
           const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left Panel: Saved Configs
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              children: [
                AppBar(
                  title: const Text('Configs', style: TextStyle(fontSize: 16)),
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  actions: [
                    IconButton(onPressed: () => _showAddConfigDialog(context, ref), icon: const Icon(Icons.add)),
                  ],
                ),
                Expanded(
                  child: configsAsync.when(
                    data: (configs) => ListView.builder(
                      itemCount: configs.length,
                      itemBuilder: (context, index) {
                        final config = configs[index];
                        final isSelected = config.id == state.selectedConfigId;
                        return ListTile(
                          title: Text(config.name),
                          subtitle: Text(config.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                          selected: isSelected,
                          onTap: () {
                             ref.read(webSocketClientProvider.notifier).selectConfig(config.id);
                          },
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                            onSelected: (value) {
                              if (value == 'delete') {
                                ref.read(webSocketConfigRepositoryProvider).delete(config.id);
                                ref.refresh(websocketConfigsProvider);
                              } else if (value == 'duplicate') {
                                ref.read(webSocketConfigRepositoryProvider).duplicate(config.id);
                                ref.refresh(websocketConfigsProvider);
                              }
                            },
                          ),
                        );
                      },
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content: Reusable Panel
          const Expanded(
            child: WebSocketClientPanel(),
          ),
        ],
      ),
    );
  }

  void _showAddConfigDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New WebSocket Config'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                 await ref.read(webSocketConfigRepositoryProvider).saveNew(
                   name: nameCtrl.text, 
                   url: urlCtrl.text
                 );
                 ref.refresh(websocketConfigsProvider);
                 if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _ConnectionStatusBadge extends StatelessWidget {
  final WebSocketConnectionStatus status;
  const _ConnectionStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case WebSocketConnectionStatus.connected: color = Colors.green; label = 'CONNECTED'; break;
      case WebSocketConnectionStatus.connecting: color = Colors.orange; label = 'CONNECTING'; break;
      case WebSocketConnectionStatus.disconnected: color = Colors.grey; label = 'DISCONNECTED'; break;
      case WebSocketConnectionStatus.error: color = Colors.red; label = 'ERROR'; break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

// Simple Provider for fetching config list (Duplicated or moved to common? Ideally common but keeping here for scope)
final websocketConfigsProvider = FutureProvider<List<WebSocketConfig>>((ref) async {
  return ref.watch(webSocketConfigRepositoryProvider).getAll();
});

extension WebSocketConfigRepoExt on WebSocketConfigRepository {
  Future<WebSocketConfig> saveNew(WebSocketConfig config) async {
     await save(config);
     return config;
  }
}
