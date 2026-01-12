import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../history/providers/history_provider.dart';
import '../../history/models/history_item.dart';
import '../../request/providers/request_provider.dart';
import '../../request/models/key_value_item.dart';
import '../../request/models/request_model.dart'; // for AuthType enum mapping
import '../../workgroup/presentation/widgets/workgroup_explorer.dart';

class HistoryPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  const HistoryPanel({super.key, required this.onClose});

  @override
  ConsumerState<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends ConsumerState<HistoryPanel> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyNotifierProvider);

    return DefaultTabController(
      length: 2,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade300)),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Text('Sidebar', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
                ],
              ),
            ),
            
            // Tabs
            const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: 'Explorer', icon: Icon(Icons.folder_open, size: 20)),
                Tab(text: 'History', icon: Icon(Icons.history, size: 20)),
              ],
            ),
            
            Expanded(
              child: TabBarView(
                children: [
                   // Tab 1: Explorer
                   const WorkgroupExplorer(),

                   // Tab 2: History (Existing Code wrapper)
                   Column(
                     children: [
                        // Search
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search URL/Method',
                              prefixIcon: Icon(Icons.search),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              ref.read(historyNotifierProvider.notifier).search(val);
                            },
                          ),
                        ),
                        
                        const Divider(),

                        // List
                        Expanded(
                          child: historyAsync.when(
                            data: (items) {
                              if (items.isEmpty) {
                                return const Center(child: Text('No history items'));
                              }
                              return ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      item.url.isEmpty ? 'No URL' : item.url,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Text(
                                          item.method,
                                          style: TextStyle(
                                            color: _getMethodColor(item.method),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('${item.statusCode}', style: TextStyle(
                                           color: item.statusCode >= 200 && item.statusCode < 300 ? Colors.green : Colors.red,
                                        )),
                                        const Spacer(),
                                        Text(
                                          DateFormat('MM/dd HH:mm').format(item.createdAt),
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      onPressed: () {
                                         ref.read(historyNotifierProvider.notifier).deleteHistory(item.id);
                                      },
                                    ),
                                    onTap: () => _restoreHistory(item),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, _) => Center(child: Text('Error: $err')),
                          ),
                        ),
                     ],
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _restoreHistory(HistoryItem item) {
    try {
      final headersList = (jsonDecode(item.headersJson) as List).map((e) => 
        KeyValueItem(id: Uuid().v4(), key: e['key'], value: e['value'], isEnabled: e['isEnabled'])
      ).toList();

      final paramsList = (jsonDecode(item.paramsJson) as List).map((e) => 
        KeyValueItem(id: Uuid().v4(), key: e['key'], value: e['value'], isEnabled: e['isEnabled'])
      ).toList();
      
      final authData = jsonDecode(item.authJson);
      final AuthType authType = AuthType.values.firstWhere(
        (e) => e.name == authData['type'], 
        orElse: () => AuthType.none
      );
      
      final model = RequestModel(
        id: Uuid().v4(), // temporary
        method: item.method,
        url: item.url,
        headers: headersList,
        params: paramsList,
        body: item.body,
        authType: authType,
        authData: Map<String, String>.from(authData['data']),
      );

      ref.read(requestNotifierProvider.notifier).restoreRequest(model);
      
      widget.onClose(); // Close panel after restore
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Restored')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to restore: $e')));
    }
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET': return Colors.blue;
      case 'POST': return Colors.green;
      case 'PUT': return Colors.orange;
      case 'DELETE': return Colors.red;
      default: return Colors.grey;
    }
  }
}
