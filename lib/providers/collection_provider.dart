import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/api_collection_model.dart';
import '../models/http_request_model.dart';
import '../models/workflow_graph_model.dart';
import '../services/collection_service.dart';
import '../services/storage_service.dart';
import '../services/batch_execution_service.dart';

class CollectionProvider extends ChangeNotifier {
  final CollectionService _collectionService = CollectionService();
  final StorageService _storageService = StorageService();
  final BatchExecutionService _batchService = BatchExecutionService();

  // Auto-save timer
  Timer? _autoSaveTimer;

  // Collections list
  List<ApiCollectionModel> _collections = [];
  ApiCollectionModel? _activeCollection;

  // Loading and error states
  bool _isLoading = false;
  String? _error;

  // Batch execution state
  bool _isBatchExecuting = false;
  int _batchProgress = 0;
  int _batchTotal = 0;
  String _currentRequestName = '';
  List<BatchExecutionResult> _lastBatchResults = [];

  // Getters
  List<ApiCollectionModel> get collections => _collections;
  ApiCollectionModel? get activeCollection => _activeCollection;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isBatchExecuting => _isBatchExecuting;
  int get batchProgress => _batchProgress;
  int get batchTotal => _batchTotal;
  String get currentRequestName => _currentRequestName;
  List<BatchExecutionResult> get lastBatchResults => _lastBatchResults;

  // Initialize provider
  Future<void> init() async {
    await _loadCollectionsFromDisk();
    await _loadLastActiveCollection();
  }

  // Load all collections from disk
  Future<void> _loadCollectionsFromDisk() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loadedCollections = await _collectionService.loadAllCollections();
      _collections = loadedCollections;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load collections metadata from storage
  Future<void> loadCollectionsMetadata() async {
    _isLoading = true;
    notifyListeners();

    try {
      final metadata = await _storageService.getCollectionsMetadata();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load last active collection
  Future<void> _loadLastActiveCollection() async {
    final lastCollectionId = await _storageService.getLastActiveCollectionId();
    if (lastCollectionId != null && lastCollectionId.isNotEmpty) {
      final collection = getCollectionById(lastCollectionId);
      if (collection != null) {
        _activeCollection = collection;
        notifyListeners();
      }
    }
  }

  // Save last active collection ID
  Future<void> _saveLastActiveCollectionId(String? collectionId) async {
    await _storageService.saveLastActiveCollectionId(collectionId);
  }

  // Create new collection
  void createCollection(String name, {String description = ''}) {
    final collection = ApiCollectionModel(
      name: name,
      description: description,
      chainMode: true, // Enable chain mode by default
    );

    _collections.add(collection);
    _activeCollection = collection;
    _saveMetadata();
    _saveLastActiveCollectionId(collection.id);
    notifyListeners();
  }

  // Update collection
  void updateCollection(ApiCollectionModel updatedCollection) async {
    final index = _collections.indexWhere((c) => c.id == updatedCollection.id);
    if (index != -1) {
      _collections[index] = updatedCollection;
      if (_activeCollection?.id == updatedCollection.id) {
        _activeCollection = updatedCollection;
      }
      _saveMetadata();
      // Auto-save to file
      await _autoSaveCollection(updatedCollection);
      notifyListeners();
    }
  }

  // Auto-save collection to file
  Future<void> _autoSaveCollection(ApiCollectionModel collection) async {
    try {
      await _collectionService.saveCollectionToFile(collection);
    } catch (e) {
      // Silent fail for auto-save
      print('Auto-save failed: $e');
    }
  }

  // Delete collection
  void deleteCollection(String collectionId) {
    _collections.removeWhere((c) => c.id == collectionId);
    if (_activeCollection?.id == collectionId) {
      _activeCollection = null;
    }
    _saveMetadata();
    notifyListeners();
  }

  // Set active collection
  void setActiveCollection(ApiCollectionModel? collection) {
    _activeCollection = collection;
    _saveLastActiveCollectionId(collection?.id);
    notifyListeners();
  }

  // Add request to active collection
  void addRequestToActiveCollection(HttpRequestModel request) {
    final updatedCollection = _activeCollection!.addRequest(request);
    
    // Create a node for this new request
    final newNode = WorkflowNode(
      id: Uuid().v4(),
      requestId: request.id,
      label: request.url.isNotEmpty ? request.url : request.name,
      position: Offset(100.0 * updatedCollection.nodes.length, 100.0),
    );
    
    final finalCollection = updatedCollection.copyWith(
      nodes: [...updatedCollection.nodes, newNode],
    );
    
    updateCollection(finalCollection);
  }

  /// Injects AI-generated nodes and edges into a collection
  void addWorkflowFromAI(String collectionId, List<WorkflowNode> nodes, List<WorkflowEdge> edges) {
    final collection = getCollectionById(collectionId);
    if (collection == null) return;

    final updatedCollection = collection.copyWith(
      nodes: [...collection.nodes, ...nodes],
      edges: [...collection.edges, ...edges],
    );

    updateCollection(updatedCollection);
  }

  void addRequestNode(String collectionId, String requestId, Offset position) {
    final collection = getCollectionById(collectionId);
    if (collection == null) return;

    final request = collection.requests.firstWhere((r) => r.id == requestId, orElse: () => HttpRequestModel(id: '', name: 'Deleted', method: '', url: ''));
    if (request.id.isEmpty) return;


    final newNode = WorkflowNode(
      id: Uuid().v4(),
      requestId: requestId,
      label: request.name,
      position: position,
    );
    
    updateCollection(collection.copyWith(
      nodes: [...collection.nodes, newNode],
    ));
  }

  // Add a logic node
  void addLogicNode(String collectionId, String type, String label) {
    final collection = getCollectionById(collectionId);
    if (collection == null) return;

    final newNode = WorkflowNode(
      id: Uuid().v4(),
      type: type,
      label: label,
      position: const Offset(100, 100),
    );
    
    updateCollection(collection.copyWith(
      nodes: [...collection.nodes, newNode],
    ));
  }

  // Remove request from active collection
  void removeRequestFromActiveCollection(String requestId) {
    if (_activeCollection == null) return;

    final updatedCollection = _activeCollection!.removeRequest(requestId);
    updateCollection(updatedCollection);
  }

  // Update request in active collection
  void updateRequestInActiveCollection(HttpRequestModel updatedRequest) {
    if (_activeCollection == null) return;

    final updatedCollection = _activeCollection!.updateRequest(updatedRequest);
    updateCollection(updatedCollection);
  }

  // Node & Edge management
  void updateNodePosition(String collectionId, String nodeId, Offset newPosition) {
    final collection = getCollectionById(collectionId);
    if (collection == null) return;

    final updatedNodes = collection.nodes.map((node) {
      if (node.id == nodeId) {
        return node.copyWith(position: newPosition);
      }
      return node;
    }).toList();

    updateCollection(collection.copyWith(nodes: updatedNodes));
  }

  void updateNodeConfig(String collectionId, String nodeId, String label, Map<String, dynamic> config) {
    final collection = getCollectionById(collectionId);
    if (collection == null) return;

    final updatedNodes = collection.nodes.map((node) {
      if (node.id == nodeId) {
        return node.copyWith(label: label, config: config);
      }
      return node;
    }).toList();

    updateCollection(collection.copyWith(nodes: updatedNodes));
  }

  void deleteNode(String collectionId, String nodeId) {
    final collection = getCollectionById(collectionId);
    if (collection == null) return;

    final updatedNodes = collection.nodes.where((node) => node.id != nodeId).toList();
    final updatedEdges = collection.edges.where((edge) => edge.fromNodeId != nodeId && edge.toNodeId != nodeId).toList();
    
    updateCollection(collection.copyWith(
      nodes: updatedNodes,
      edges: updatedEdges,
    ));
  }

  void addEdge(String collectionId, WorkflowEdge edge) {
    final collection = getCollectionById(collectionId);
    if (collection == null) return;

    // Prevent duplicate edges (same from/to/port)
    if (collection.edges.any((e) => 
      e.fromNodeId == edge.fromNodeId && 
      e.toNodeId == edge.toNodeId && 
      e.fromPort == edge.fromPort)) return;

    final updatedEdges = List<WorkflowEdge>.from(collection.edges)..add(edge);
    updateCollection(collection.copyWith(edges: updatedEdges));
  }

  void updateEdge(String collectionId, WorkflowEdge updatedEdge) {
    final collection = getCollectionById(collectionId);
    if (collection == null) return;

    final updatedEdges = collection.edges.map((edge) {
      return edge.id == updatedEdge.id ? updatedEdge : edge;
    }).toList();

    updateCollection(collection.copyWith(edges: updatedEdges));
  }

  // Update request in specific collection by ID
  void updateRequestInCollection(String collectionId, HttpRequestModel updatedRequest) {
    final collection = getCollectionById(collectionId);
    if (collection == null) return;

    final updatedCollection = collection.updateRequest(updatedRequest);
    
    // Update corresponding node label
    final updatedNodes = updatedCollection.nodes.map((node) {
      if (node.requestId == updatedRequest.id) {
        return node.copyWith(label: updatedRequest.name);
      }
      return node;
    }).toList();
    
    updateCollection(updatedCollection.copyWith(nodes: updatedNodes));
  }

  // Export collection to file
  Future<String?> exportCollection(ApiCollectionModel collection) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final path = await _collectionService.exportCollection(collection);
      _isLoading = false;
      notifyListeners();
      return path;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Import collection from file
  Future<ApiCollectionModel?> importCollection() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final collection = await _collectionService.importCollection();
      
      if (collection != null) {
        // Check if collection with same ID already exists
        final existingIndex = _collections.indexWhere((c) => c.id == collection.id);
        
        if (existingIndex != -1) {
          // Update existing collection
          _collections[existingIndex] = collection;
        } else {
          // Add new collection
          _collections.add(collection);
        }
        
        _activeCollection = collection;
        _saveMetadata();
      }

      _isLoading = false;
      notifyListeners();
      return collection;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Save collections metadata
  Future<void> _saveMetadata() async {
    final metadata = _collections.map((c) => {
      'id': c.id,
      'name': c.name,
    }).toList();
    
    await _storageService.saveCollectionsMetadata(metadata);
  }

  // Get collection by ID
  ApiCollectionModel? getCollectionById(String id) {
    try {
      return _collections.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Toggle chain mode for collection
  void toggleChainMode(String collectionId) {
    final index = _collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final collection = _collections[index];
      _collections[index] = collection.copyWith(chainMode: !collection.chainMode);
      
      if (_activeCollection?.id == collectionId) {
        _activeCollection = _collections[index];
      }
      
      _triggerAutoSave();
      notifyListeners();
    }
  }

  // Toggle collection expanded state
  void toggleCollectionExpanded(String collectionId) {
    final index = _collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final collection = _collections[index];
      _collections[index] = collection.copyWith(isExpanded: !collection.isExpanded);
      
      if (_activeCollection?.id == collectionId) {
        _activeCollection = _collections[index];
      }
      
      _triggerAutoSave();
      notifyListeners();
    }
  }

  // Auto-save with debounce
  void _triggerAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveMetadata();
    });
  }

  // Execute all requests in a collection
  Future<void> executeBatchCollection(ApiCollectionModel collection) async {
    _isBatchExecuting = true;
    _batchProgress = 0;
    _batchTotal = 0;
    _error = null;
    
    // Calculate total iterations
    for (var request in collection.requests) {
      _batchTotal += request.iterationCount;
    }
    
    notifyListeners();

    try {
      final results = await _batchService.executeCollection(
        collection,
        (current, total, requestName) {
          _batchProgress = current;
          _batchTotal = total;
          _currentRequestName = requestName;
          notifyListeners();
        },
      );

      _lastBatchResults = results;

      _isBatchExecuting = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isBatchExecuting = false;
      notifyListeners();
    }
  }

  // Cancel batch execution
  void cancelBatchExecution() {
    _batchService.cancel();
    _isBatchExecuting = false;
    notifyListeners();
  }

  // Clear batch results (logs)
  void clearBatchResults() {
    _lastBatchResults = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
