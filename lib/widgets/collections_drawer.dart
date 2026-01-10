import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../providers/request_provider.dart';
import '../dialogs/create_collection_dialog.dart';
import '../screens/collection_detail_screen.dart';
import '../theme/app_theme.dart';

class CollectionsDrawer extends StatelessWidget {
  final bool isInLNB;
  
  const CollectionsDrawer({super.key, this.isInLNB = false});

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
                  const Icon(Icons.folder, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Collections',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (!isInLNB)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _createCollection(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _importCollection(context),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Collections list
            Expanded(
              child: Consumer<CollectionProvider>(
                builder: (context, provider, child) {
                  if (provider.collections.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No collections yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create or import a collection',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.collections.length,
                    itemBuilder: (context, index) {
                      final collection = provider.collections[index];
                      final isActive = provider.activeCollection?.id == collection.id;

                      return ExpansionTile(
                        leading: Icon(
                          Icons.folder,
                          color: isActive ? AppTheme.cyanTeal : null,
                        ),
                        title: Text(
                          collection.name,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? AppTheme.cyanTeal : null,
                          ),
                        ),
                        subtitle: Text(
                          '${collection.requests.length} requests',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Run All button
                            if (collection.requests.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.play_arrow, size: 20),
                                onPressed: () => _runAllRequests(context, collection),
                                tooltip: 'Run All',
                              ),
                            // Menu button
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(Icons.visibility, size: 18),
                                      SizedBox(width: 8),
                                      Text('View Details'),
                                    ],
                                  ),
                                  onTap: () => _viewCollectionDetails(context, collection),
                                ),
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(Icons.download, size: 18),
                                      SizedBox(width: 8),
                                      Text('Export'),
                                    ],
                                  ),
                                  onTap: () => _exportCollection(context, collection),
                                ),
                                PopupMenuItem(
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 18, color: AppTheme.errorRed),
                                      const SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                                    ],
                                  ),
                                  onTap: () => _deleteCollection(context, collection.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                        initiallyExpanded: collection.isExpanded,
                        onExpansionChanged: (expanded) {
                          provider.toggleCollectionExpanded(collection.id);
                        },
                        children: collection.requests.map((request) {
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(left: 72, right: 16),
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getMethodColor(request.method),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                request.method,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              request.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Text(
                              'Run ${request.iterationCount}x',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                            onTap: () {
                              provider.setActiveCollection(collection);
                              context.read<RequestProvider>().loadRequest(request);
                              if (!isInLNB) {
                                Navigator.pop(context);
                              }
                            },
                          );
                        }).toList(),
                      );
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

  Future<void> _createCollection(BuildContext context) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CreateCollectionDialog(),
    );

    if (result != null) {
      if (context.mounted) {
        context.read<CollectionProvider>().createCollection(
              result['name']!,
              description: result['description'] ?? '',
            );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Collection "${result['name']}" created')),
        );
      }
    }
  }

  Future<void> _importCollection(BuildContext context) async {
    final provider = context.read<CollectionProvider>();

    try {
      final collection = await provider.importCollection();

      if (collection != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported "${collection.name}"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import: $e')),
        );
      }
    }
  }

  Future<void> _exportCollection(BuildContext context, collection) async {
    final provider = context.read<CollectionProvider>();

    try {
      final path = await provider.exportCollection(collection);

      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e')),
        );
      }
    }
  }

  Future<void> _deleteCollection(BuildContext context, String collectionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection'),
        content: const Text('Are you sure you want to delete this collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CollectionProvider>().deleteCollection(collectionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection deleted')),
      );
    }
  }

  Future<void> _viewCollectionDetails(BuildContext context, collection) async {
    // Delay to allow popup menu to close
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollectionDetailScreen(collectionId: collection.id),
        ),
      );
    }
  }

  Future<void> _runAllRequests(BuildContext context, collection) async {
    final provider = context.read<CollectionProvider>();
    
    // Get fresh collection from provider to ensure we have latest data
    final freshCollection = provider.getCollectionById(collection.id);
    if (freshCollection == null || freshCollection.requests.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No requests to execute')),
        );
      }
      return;
    }
    
    if (!isInLNB) {
      Navigator.pop(context); // Close drawer
    }
    
    try {
      await provider.executeBatchCollection(freshCollection);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Completed ${freshCollection.requests.length} requests'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return AppTheme.successGreen;
      case 'POST':
        return AppTheme.cyanTeal;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return AppTheme.errorRed;
      case 'PATCH':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
