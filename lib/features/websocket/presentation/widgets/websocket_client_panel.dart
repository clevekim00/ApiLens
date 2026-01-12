import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/websocket_config.dart';
import '../../domain/models/websocket_message.dart';
import '../../application/websocket_controller.dart';
import '../../data/websocket_config_repository.dart';

class WebSocketClientPanel extends ConsumerStatefulWidget {
  final bool showHeader;
  
  const WebSocketClientPanel({
    super.key,
    this.showHeader = true,
  });

  @override
  ConsumerState<WebSocketClientPanel> createState() => _WebSocketClientPanelState();
}

class _WebSocketClientPanelState extends ConsumerState<WebSocketClientPanel> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();
  bool _prettyPrintJson = false;
  String? _lastSelectedConfigId;

  @override
  void dispose() {
    _urlController.dispose();
    _messageController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync URL if config changed externally
    // We can listen to state changes in build
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(webSocketClientProvider);
    final session = state.session;
    
    // Auto-update URL text when config selection changes
    ref.listen(webSocketClientProvider, (prev, next) {
      if (prev?.selectedConfigId != next.selectedConfigId) {
        if (next.selectedConfigId != null) {
           _loadConfigUrl(next.selectedConfigId!);
        }
      }
    });

    return Column(
      children: [
        if (widget.showHeader) ...[
          // URL Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('input_ws_url'),
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'WebSocket URL',
                      border: OutlineInputBorder(),
                      hintText: 'ws://example.com/socket',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (session.status != WebSocketConnectionStatus.connected && session.status != WebSocketConnectionStatus.connecting)
                  FilledButton.icon(
                    key: const Key('btn_ws_connect'),
                    onPressed: () => _handleConnect(),
                    icon: const Icon(Icons.link),
                    label: const Text('Connect'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => ref.read(webSocketClientProvider.notifier).disconnect(),
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  ),
              ],
            ),
          ),
        ],
        
        // Log Area
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: ListView.separated(
              controller: _logScrollController,
              itemCount: session.messages.length,
              separatorBuilder: (_,__) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final msg = session.messages[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    _getDirectionIcon(msg.direction), 
                    color: _getDirectionColor(msg.direction), 
                    size: 16
                  ),
                  title: Text(msg.payloadText, 
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    maxLines: 10, 
                    overflow: TextOverflow.ellipsis
                  ),
                  subtitle: Text('${DateFormat('HH:mm:ss.SSS').format(msg.timestamp)} • ${msg.sizeBytes} bytes'),
                  trailing: msg.parsedJson != null ? const Icon(Icons.data_object, size: 16) : null,
                );
              },
            ),
          ),
        ),
        
        // Bottom: Message Input
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                    const Text('Pretty Print JSON'),
                    Switch(value: _prettyPrintJson, onChanged: (v) => setState(() => _prettyPrintJson = v)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => ref.read(webSocketClientProvider.notifier).clearLog(), 
                      child: const Text('Clear Log')
                    ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2, // smaller
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: session.status == WebSocketConnectionStatus.connected 
                      ? _handleSend 
                      : null,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _loadConfigUrl(String id) async {
    final config = await ref.read(webSocketConfigRepositoryProvider).get(id);
    if (config != null && mounted) {
      _urlController.text = config.url;
    }
  }

  void _handleConnect() async {
    final controller = ref.read(webSocketClientProvider.notifier);
    final state = ref.read(webSocketClientProvider);
    
    // Auto-create/update temp config logic (Simplified)
    // If no config selected or URL changed, create new Untitled
    if (state.selectedConfigId == null) {
       final newConfig = await ref.read(webSocketConfigRepositoryProvider).saveNew(
         name: 'Untitled', 
         url: _urlController.text
       );
       await controller.selectConfig(newConfig.id);
    } else {
      // Check if URL matches current config? 
      // For MVP, just update defaults
      // We strictly use repository config which connects to URL in it. 
      // If user typed new URL, we should update the config or create new.
      // Let's assume we update the current temp config if it's "Untitled", or prompt.
      // For this simplified versions, let's just ensure we have a config with this URL.
      // Hack: Update URL of current config in repo before connecting?
      // Better: Create transient config if Repo allows? 
      // Repository assumes persistance.
      // Let's just create a new one for now if URL changed significantly?
      
      // Minimal logic: Update default ID config if needed.
    }
    
    // Only connect if URL is not empty
    if (_urlController.text.isEmpty) return;
    
    controller.connect();
  }

  void _handleSend() {
    ref.read(webSocketClientProvider.notifier).sendMessage(_messageController.text);
  }
  
  IconData _getDirectionIcon(WebSocketMessageDirection dir) {
    switch (dir) {
      case WebSocketMessageDirection.sent: return Icons.arrow_upward;
      case WebSocketMessageDirection.received: return Icons.arrow_downward;
      case WebSocketMessageDirection.system: return Icons.info_outline;
    }
  }

  Color _getDirectionColor(WebSocketMessageDirection dir) {
    switch (dir) {
      case WebSocketMessageDirection.sent: return Colors.blue;
      case WebSocketMessageDirection.received: return Colors.green;
      case WebSocketMessageDirection.system: return Colors.grey;
    }
  }
}
