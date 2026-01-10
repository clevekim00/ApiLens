import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/collection_provider.dart';
import '../providers/request_provider.dart';
import '../models/api_collection_model.dart';
import '../models/http_request_model.dart';
import '../widgets/response_viewer.dart';
import '../widgets/response_detail_view.dart';
import '../services/batch_execution_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flow_editor/workflow_canvas.dart';
import '../widgets/flow_editor/console_viewer.dart';
import '../models/workflow_graph_model.dart';
import '../dialogs/data_mapping_dialog.dart';
import '../dialogs/logic_node_dialog.dart';

class CollectionDetailScreen extends StatelessWidget {
  final String collectionId; // Use ID instead of object to avoid stale data

  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
  });

  @override
  Widget build(BuildContext context) {
    return _CollectionDetailContent(collectionId: collectionId);
  }
}

class _CollectionDetailContent extends StatefulWidget {
  final String collectionId;

  const _CollectionDetailContent({required this.collectionId});

  @override
  State<_CollectionDetailContent> createState() => _CollectionDetailContentState();
}

class _CollectionDetailContentState extends State<_CollectionDetailContent> {
  bool _isFlowView = false;
  bool _showConsole = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CollectionProvider>(
        builder: (context, provider, child) {
          // Always get fresh collection from provider
          final collection = provider.getCollectionById(widget.collectionId);
          
          if (collection == null) {
            return const Center(child: Text('Collection not found'));
          }

          return Row(
            children: [
              // Left: Request list
              Container(
                width: 400,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    right: BorderSide(color: Colors.grey[800]!),
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[800]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _EditableTitle(
                              initialValue: collection.name,
                              onChanged: (newName) {
                                if (newName.isNotEmpty) {
                                  final updated = collection.copyWith(name: newName);
                                  provider.updateCollection(updated);
                                }
                              },
                            ),
                          ),
                          if (collection.chainMode)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.cyanTeal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.account_tree, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Workflow',
                                    style: TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      _isFlowView ? Icons.list : Icons.account_tree,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_isFlowView ? 'List View' : 'Flow Editor'),
                                  ],
                                ),
                                onTap: () {
                                  setState(() => _isFlowView = !_isFlowView);
                                },
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      collection.chainMode ? Icons.check_box : Icons.check_box_outline_blank,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Chain Mode'),
                                  ],
                                ),
                                onTap: () {
                                  provider.toggleChainMode(collection.id);
                                },
                              ),
                            ],
                          ),
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: collection.requests.isEmpty
                                  ? null
                                  : () => _runAll(context, provider, collection),
                              tooltip: 'Run All Requests',
                            ),
                            if (_isFlowView)
                              IconButton(
                                icon: Icon(_showConsole ? Icons.terminal : Icons.terminal_outlined),
                                color: _showConsole ? AppTheme.cyanTeal : null,
                                onPressed: () => setState(() => _showConsole = !_showConsole),
                                tooltip: 'Toggle Console',
                              ),
                        ],
                      ),
                    ),

                    // Chain mode help banner
                    if (collection.chainMode)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cyanTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cyanTeal.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_tree, size: 16, color: AppTheme.cyanTeal),
                                const SizedBox(width: 8),
                                Text(
                                  'Workflow Mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppTheme.cyanTeal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '{{step0.response.body.field}}',
                              style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),

                    // Batch execution progress
                    if (provider.isBatchExecuting)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: AppTheme.cyanTeal.withOpacity(0.1),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const CircularProgressIndicator(strokeWidth: 2),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Running: ${provider.currentRequestName}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      Text(
                                        'Progress: ${provider.batchProgress}/${provider.batchTotal}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => provider.cancelBatchExecution(),
                                  child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: provider.batchTotal > 0
                                  ? provider.batchProgress / provider.batchTotal
                                  : 0,
                            ),
                          ],
                        ),
                      ),

                    // Requests list
                    Expanded(
                      child: collection.requests.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox, size: 48, color: Colors.grey[600]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No requests',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: collection.requests.length,
                              itemBuilder: (context, index) {
                                final request = collection.requests[index];
                                return _RequestListTile(
                                  request: request,
                                  collectionId: collection.id,
                                  onTap: () => _loadRequest(context, request),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              // Right: Content area (Flow Editor or List View)
              Expanded(
                child: _isFlowView
                    ? Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: WorkflowCanvas(
                              nodes: collection.nodes,
                              edges: collection.edges,
                              results: provider.lastBatchResults,
                              onNodeMoved: (nodeId, pos) => provider.updateNodePosition(collection.id, nodeId, pos),
                              onNodeSelected: (node) => _handleNodeSelection(context, provider, collection, node),
                              onNodeDeleted: (nodeId) => provider.deleteNode(collection.id, nodeId),
                              onAddLogicNode: (type, label) => provider.addLogicNode(collection.id, type, label),
                              onEdgeAdded: (edge) => provider.addEdge(collection.id, edge),
                              onEdgeSelected: (edge) => _showDataMappingDialog(context, provider, collection, edge),
                              onAddRequestNode: (requestId, pos) => provider.addRequestNode(collection.id, requestId, pos),
                            ),
                          ),
                          if (_showConsole)
                            Expanded(
                              flex: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.grey[800]!, width: 1),
                                  ),
                                ),
                                child: ConsoleViewer(
                                  results: provider.lastBatchResults,
                                  onClear: () => provider.clearBatchResults(),
                                ),
                              ),
                            ),
                        ],
                      )
                    : provider.lastBatchResults.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            child: BatchResultsView(results: provider.lastBatchResults),
                          )
                        : Container(
                            padding: const EdgeInsets.all(16),
                            child: const ResponseViewer(),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _runAll(BuildContext context, CollectionProvider provider, ApiCollectionModel collection) async {
    await provider.executeBatchCollection(collection);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch execution completed')),
      );
    }
  }

  void _loadRequest(BuildContext context, HttpRequestModel request) {
    final requestProvider = context.read<RequestProvider>();
    requestProvider.loadRequest(request);
  }

  void _showDataMappingDialog(
    BuildContext context,
    CollectionProvider provider,
    ApiCollectionModel collection,
    WorkflowEdge edge,
  ) async {
    final fromNode = collection.nodes.firstWhere((n) => n.id == edge.fromNodeId);
    final toNode = collection.nodes.firstWhere((n) => n.id == edge.toNodeId);
    final fromRequest = fromNode.requestId != null ? collection.requests.firstWhere((r) => r.id == fromNode.requestId) : null;
    final toRequest = toNode.requestId != null ? collection.requests.firstWhere((r) => r.id == toNode.requestId) : null;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DataMappingDialog(
        edge: edge,
        fromNode: fromNode,
        toNode: toNode,
        fromRequest: fromRequest,
        toRequest: toRequest,
      ),
    );

    if (result != null) {
      final updatedEdge = WorkflowEdge(
        id: edge.id,
        fromNodeId: edge.fromNodeId,
        toNodeId: edge.toNodeId,
        fromPort: edge.fromPort,
        dataMapping: result,
      );
      provider.updateEdge(collection.id, updatedEdge);
    }
  }

  void _handleNodeSelection(
    BuildContext context,
    CollectionProvider provider,
    ApiCollectionModel collection,
    WorkflowNode node,
  ) async {
    if (node.type == 'api') {
      final request = collection.requests.firstWhere((r) => r.id == node.requestId);
      _loadRequest(context, request);
    }
    
    // Logic node or API node can be configured/labeled
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => LogicNodeDialog(node: node),
    );

    if (result != null) {
      provider.updateNodeConfig(
        collection.id,
        node.id,
        result['label'],
        result['config'],
      );
    }
  }
}

// Editable title widget
class _EditableTitle extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;

  const _EditableTitle({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_EditableTitle> createState() => _EditableTitleState();
}

class _EditableTitleState extends State<_EditableTitle> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(_EditableTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && !_isEditing) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          setState(() => _isEditing = false);
          widget.onChanged(value);
        },
        onTapOutside: (_) {
          setState(() => _isEditing = false);
          widget.onChanged(_controller.text);
        },
      );
    }

    return InkWell(
      onTap: () => setState(() => _isEditing = true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.initialValue,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Icon(Icons.edit, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

// Request list tile
class _RequestListTile extends StatefulWidget {
  final HttpRequestModel request;
  final String collectionId;
  final VoidCallback onTap;

  const _RequestListTile({
    required this.request,
    required this.collectionId,
    required this.onTap,
  });

  @override
  State<_RequestListTile> createState() => _RequestListTileState();
}

class _RequestListTileState extends State<_RequestListTile> {
  late TextEditingController _iterationController;
  late TextEditingController _nameController;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _iterationController = TextEditingController(
      text: widget.request.iterationCount.toString(),
    );
    _nameController = TextEditingController(text: widget.request.name);
  }

  @override
  void didUpdateWidget(_RequestListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.request.name != oldWidget.request.name && !_isEditingName) {
      _nameController.text = widget.request.name;
    }
  }

  @override
  void dispose() {
    _iterationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<Map<String, dynamic>>(
      data: {'requestId': widget.request.id},
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.cyanTeal),
          ),
          child: Text(
            widget.request.name,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            dense: true,
            title: Text(widget.request.name),
          ),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getMethodColor(widget.request.method),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.request.method,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: _isEditingName
                  ? TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        setState(() => _isEditingName = false);
                        _updateRequestName(value);
                      },
                      onTapOutside: (_) {
                        setState(() => _isEditingName = false);
                        _updateRequestName(_nameController.text);
                      },
                    )
                  : Text(
                      widget.request.name,
                      style: const TextStyle(fontSize: 13),
                    ),
            ),
            if (!_isEditingName)
              IconButton(
                icon: Icon(Icons.edit, size: 14, color: Colors.grey[600]),
                onPressed: () => setState(() => _isEditingName = true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit name',
              ),
          ],
        ),
        subtitle: Text(
          widget.request.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Iteration count
            SizedBox(
              width: 60,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Run', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 30,
                    child: TextField(
                      controller: _iterationController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                        suffix: Text('x', style: TextStyle(fontSize: 10)),
                      ),
                      onChanged: (value) {
                        final count = int.tryParse(value) ?? 1;
                        if (count >= 1 && count <= 100) {
                          _updateIterationCount(count);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              onPressed: () => _deleteRequest(context),
              tooltip: 'Remove',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        onTap: widget.onTap,
      ),
    ),
  );
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

  void _updateIterationCount(int count) {
    final provider = context.read<CollectionProvider>();
    final updatedRequest = widget.request.copyWith(iterationCount: count);
    provider.updateRequestInCollection(widget.collectionId, updatedRequest);
  }

  void _updateRequestName(String name) {
    if (name.isNotEmpty && name != widget.request.name) {
      final provider = context.read<CollectionProvider>();
      final updatedRequest = widget.request.copyWith(name: name);
      provider.updateRequestInCollection(widget.collectionId, updatedRequest);
    }
  }

  void _deleteRequest(BuildContext context) {
    final provider = context.read<CollectionProvider>();
    // Set this collection as active first, then remove
    final collection = provider.getCollectionById(widget.collectionId);
    if (collection != null) {
      provider.setActiveCollection(collection);
      provider.removeRequestFromActiveCollection(widget.request.id);
    }
  }
}

class BatchResultsView extends StatelessWidget {
  final List<BatchExecutionResult> results;

  const BatchResultsView({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.assignment, color: AppTheme.cyanTeal),
            const SizedBox(width: 12),
            Text(
              'Batch Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: DefaultTabController(
            length: results.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  labelColor: AppTheme.cyanTeal,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.cyanTeal,
                  tabs: results.map((r) => Tab(text: r.request.name)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: results.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ResponseDetailView(
                          response: r.response,
                          error: r.error,
                          showBadges: true,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
