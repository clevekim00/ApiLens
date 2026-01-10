import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/request_provider.dart';
import '../models/http_request_model.dart';

class HistoryDrawer extends StatefulWidget {
  final bool isInLNB;
  
  const HistoryDrawer({super.key, this.isInLNB = false});

  @override
  State<HistoryDrawer> createState() => _HistoryDrawerState();
}

class _HistoryDrawerState extends State<HistoryDrawer> {
  final TextEditingController _searchController = TextEditingController();
  List<HttpRequestModel> _filteredHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadHistory() {
    final provider = context.read<RequestProvider>();
    setState(() {
      _filteredHistory = provider.history;
    });
  }

  void _searchHistory(String query) async {
    final provider = context.read<RequestProvider>();
    final results = await provider.searchHistory(query);
    setState(() {
      _filteredHistory = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Request History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (!widget.isInLNB)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search history...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _searchHistory,
              ),
            ),

            // Clear history button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final provider = context.read<RequestProvider>();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear History'),
                        content: const Text(
                          'Are you sure you want to clear all request history?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await provider.clearHistory();
                      _loadHistory();
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear History'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // History list
            Expanded(
              child: Consumer<RequestProvider>(
                builder: (context, provider, child) {
                  if (_filteredHistory.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No history yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: _filteredHistory.length,
                    itemBuilder: (context, index) {
                      final request = _filteredHistory[index];
                      return _buildHistoryItem(context, request, provider);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    HttpRequestModel request,
    RequestProvider provider,
  ) {
    return Dismissible(
      key: Key(request.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.deleteFromHistory(request.id);
        _loadHistory();
      },
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getMethodColor(request.method),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            request.method,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          request.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          request.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: Text(
          _formatTimestamp(request.timestamp),
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
        onTap: () {
          provider.loadRequestFromHistory(request);
          if (!widget.isInLNB) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}
