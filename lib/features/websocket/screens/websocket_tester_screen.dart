import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../../core/network/websocket/websocket_manager.dart';

class WebSocketTesterScreen extends ConsumerStatefulWidget {
  const WebSocketTesterScreen({super.key});

  @override
  ConsumerState<WebSocketTesterScreen> createState() => _WebSocketTesterScreenState();
}

class _WebSocketTesterScreenState extends ConsumerState<WebSocketTesterScreen> {
  final _urlController = TextEditingController(text: 'wss://echo.websocket.org');
  final _messageController = TextEditingController(text: 'Hello WebSocket!');
  String? _activeConnectionId;

  @override
  void dispose() {
    _urlController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleConnect() async {
    final manager = ref.read(webSocketManagerProvider);
    try {
      final id = await manager.connect(_urlController.text);
      if (mounted) {
        setState(() => _activeConnectionId = id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected! ID: $id')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _handleDisconnect() {
    if (_activeConnectionId != null) {
      ref.read(webSocketManagerProvider).disconnect(_activeConnectionId!);
      setState(() => _activeConnectionId = null);
    }
  }

  void _handleSend() {
    if (_activeConnectionId == null) return;
    try {
      ref.read(webSocketManagerProvider).send(_activeConnectionId!, _messageController.text);
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(webSocketLogProvider);
    // Note: StreamProvider gives the *latest* item, not a list. 
    // WebSocketManager exposes a Stream. 
    // To show a list, we need a provider that accumulates them or use the manager's stream directly in a StreamBuilder that accumulates (or a state notifier).
    // Let's create a local list state update for simplicity or check if we can improve the provider.
    // For now, let's watch the stream and accumulate in a local list? No, that clears on rebuild.
    // Better: Make a StateNotifier for logs in the Manager or a separate provider.
    // But for this simple tester, let's use a StateProvider or just listen in `initState`.
    // Actually, `WebSocketManager` has a `logStream`.
    // Let's Create a separate Logger widget that accumulates.
    
    return Scaffold(
      appBar: AppBar(title: const Text('WebSocket Tester')),
      body: Column(
        children: [
          // Connection Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(labelText: 'WebSocket URL', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                if (_activeConnectionId == null)
                  ElevatedButton(onPressed: _handleConnect, child: const Text('Connect'))
                else
                  ElevatedButton(onPressed: _handleDisconnect, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Disconnect')),
              ],
            ),
          ),
          
          const Divider(),
          
          // Logs Area
          Expanded(
            child: _LogViewer(),
          ),
          
          const Divider(),
          
          // Message Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _activeConnectionId != null ? _handleSend : null, 
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogViewer extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends ConsumerState<_LogViewer> {
  final List<WebSocketLog> _logs = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    final manager = ref.read(webSocketManagerProvider);
    _sub = manager.logStream.listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log);
          // Auto scroll? 
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return ListTile(
          leading: Icon(
            log.isSent ? Icons.arrow_upward : Icons.arrow_downward,
            color: log.isSent ? Colors.blue : Colors.green,
            size: 16,
          ),
          title: Text(log.message),
          subtitle: Text(log.timestamp.toString().split('.').first),
          dense: true,
        );
      },
    );
  }
}
