import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/workflow_node.dart';
import '../domain/models/workflow_edge.dart';
import '../data/workflow_repository.dart';
import '../domain/models/workflow_model.dart';

class WorkflowEditorState {
  final String id;
  final String name;
  final String? groupId; // Link to parent folder
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final String? selectedNodeId;
  final String? connectingNodeId;
  final String? connectingPortKey;
  final bool isDirty;
  final DateTime? lastSavedAt;
  final String? selectedEdgeId;

  const WorkflowEditorState({
    required this.id,
    this.name = 'Untitled Workflow',
    this.groupId,
    this.nodes = const [],
    this.edges = const [],
    this.selectedNodeId,
    this.connectingNodeId,
    this.connectingPortKey,
    this.isDirty = false,
    this.lastSavedAt,
    this.selectedEdgeId,
  });

  WorkflowEditorState copyWith({
    String? id,
    String? name,
    String? groupId,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
    String? selectedNodeId,
    String? connectingNodeId,
    String? connectingPortKey,
    bool? isDirty,
    DateTime? lastSavedAt,
    String? selectedEdgeId,
  }) {
    return WorkflowEditorState(
      id: id ?? this.id,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
      connectingPortKey: connectingPortKey ?? this.connectingPortKey,
      isDirty: isDirty ?? this.isDirty,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      selectedEdgeId: selectedEdgeId ?? this.selectedEdgeId,
      connectingNodeId: connectingNodeId ?? this.connectingNodeId,
    );
  }
}

class WorkflowEditorController extends StateNotifier<WorkflowEditorState> {
  final WorkflowRepository _repository;

  WorkflowEditorController(this._repository) : super(WorkflowEditorState(
    id: const Uuid().v4(),
    nodes: [
        WorkflowNode(id: 'start', type: 'start', x: 100, y: 100),
    ],
  ));
  
  void initNewWithGroup(String? groupId) {
     state = WorkflowEditorState(
      id: const Uuid().v4(),
      name: 'Untitled Workflow',
      groupId: groupId ?? 'no-workgroup',
      nodes: [WorkflowNode(id: 'start', type: 'start', x: 100, y: 100)],
      isDirty: false,
    );
  }

  void loadWorkflow(String id, String name, List<WorkflowNode> nodes, List<WorkflowEdge> edges, {String? groupId}) {
    state = WorkflowEditorState(
        id: id, 
        name: name, 
        groupId: groupId,
        nodes: nodes, 
        edges: edges, 
        isDirty: false, 
        lastSavedAt: DateTime.now()
    );
  }
  
  void clearWorkflow() {
    state = WorkflowEditorState(
      id: const Uuid().v4(),
      name: 'Untitled Workflow',
      nodes: [WorkflowNode(id: 'start', type: 'start', x: 100, y: 100)],
      isDirty: false,
    );
  }

  Future<void> save() async {
    final model = WorkflowModel(
      id: state.id,
      name: state.name,
      groupId: state.groupId,
      nodes: state.nodes,
      edges: state.edges,
      lastSavedAt: DateTime.now(),
    );
    await _repository.save(model);
    state = state.copyWith(isDirty: false, lastSavedAt: model.lastSavedAt);
  }

  void saveAs(String newId, String newName) {
     state = state.copyWith(id: newId, name: newName, isDirty: false, lastSavedAt: DateTime.now());
  }

  void markSaved() {
    state = state.copyWith(isDirty: false, lastSavedAt: DateTime.now());
  }
  
  void updateName(String name) {
    state = state.copyWith(name: name, isDirty: true);
  }

  void addNode(WorkflowNode node) {
    state = state.copyWith(nodes: [...state.nodes, node], isDirty: true);
  }

  void setNodePosition(String id, double x, double y) {
    state = state.copyWith(
      nodes: state.nodes.map((n) {
        if (n.id == id) {
          return WorkflowNode(
              id: n.id,
              type: n.type,
              x: x, 
              y: y,
              data: n.data,
              inputPortKeys: n.inputPortKeys,
              outputPortKeys: n.outputPortKeys);
        }
        return n;
      }).toList(),
      isDirty: true,
    );
  }

  void updateNodeConfig(String id, Map<String, dynamic> newData) {
    state = state.copyWith(
      nodes: state.nodes.map((n) {
        if (n.id == id) {
           final mergedData = Map<String, dynamic>.from(n.data)..addAll(newData);
           return WorkflowNode(
              id: n.id,
              type: n.type,
              x: n.x,
              y: n.y,
              data: mergedData,
              inputPortKeys: n.inputPortKeys,
              outputPortKeys: n.outputPortKeys 
           );
        }
        return n;
      }).toList(),
      isDirty: true,
    );
  }

  void selectNode(String? id) {
    if (state.connectingNodeId != null) {
      cancelConnection();
    }
    // Direct constructor to allow nullifying selectedNodeId safely
    state = WorkflowEditorState(
      id: state.id,
      name: state.name,
      groupId: state.groupId,
      nodes: state.nodes,
      edges: state.edges,
      selectedNodeId: id,
      selectedEdgeId: null, // Clear edge selection
      connectingNodeId: state.connectingNodeId,
      connectingPortKey: state.connectingPortKey,
      isDirty: state.isDirty,
      lastSavedAt: state.lastSavedAt,
    );
  }

  void selectEdge(String? id) {
    if (state.connectingNodeId != null) cancelConnection();
    state = WorkflowEditorState(
      id: state.id,
      name: state.name,
      groupId: state.groupId,
      nodes: state.nodes,
      edges: state.edges,
      selectedNodeId: null, // Clear node selection
      selectedEdgeId: id,
      connectingNodeId: state.connectingNodeId,
      connectingPortKey: state.connectingPortKey,
      isDirty: state.isDirty,
      lastSavedAt: state.lastSavedAt,
    );
  }

  void deleteNode(String id) {
    // Cascade delete edges
    final newEdges = state.edges.where((e) => e.sourceNodeId != id && e.targetNodeId != id).toList();
    final newNodes = state.nodes.where((n) => n.id != id).toList();
    
    // Check if selected edge was deleted
    String? newSelectedEdgeForState = state.selectedEdgeId;
    if (newSelectedEdgeForState != null && !newEdges.any((e) => e.id == newSelectedEdgeForState)) {
      newSelectedEdgeForState = null;
    }

    state = WorkflowEditorState(
      id: state.id,
      name: state.name,
      groupId: state.groupId,
      nodes: newNodes,
      edges: newEdges,
      selectedNodeId: state.selectedNodeId == id ? null : state.selectedNodeId,
      selectedEdgeId: newSelectedEdgeForState,
      connectingNodeId: state.connectingNodeId,
      connectingPortKey: state.connectingPortKey,
      isDirty: true,
      lastSavedAt: state.lastSavedAt,
    );
  }
  
  void deleteEdge(String edgeId) {
    final newEdges = state.edges.where((e) => e.id != edgeId).toList();
    state = state.copyWith(
        edges: newEdges, 
        isDirty: true, 
        selectedEdgeId: state.selectedEdgeId == edgeId ? null : state.selectedEdgeId
    );
  }

  // Connection Logic
  void startConnection(String nodeId, String portKey) {
    state = WorkflowEditorState(
      id: state.id,
      name: state.name,
      groupId: state.groupId,
      nodes: state.nodes,
      edges: state.edges,
      selectedNodeId: state.selectedNodeId,
      selectedEdgeId: state.selectedEdgeId,
      connectingNodeId: nodeId,
      connectingPortKey: portKey,
      isDirty: state.isDirty,
      lastSavedAt: state.lastSavedAt,
    );
  }

  void completeConnection(String targetNodeId, String targetPortKey) {
    if (state.connectingNodeId == null || state.connectingPortKey == null) return;
    
    final sourceId = state.connectingNodeId!;
    final sourcePort = state.connectingPortKey!;
    
    // Prevent self-connection
    if (sourceId == targetNodeId) return;

    addEdge(sourceId, targetNodeId, sourcePort, targetPortKey);
    cancelConnection();
  }

  void cancelConnection() {
    state = WorkflowEditorState(
      id: state.id,
      name: state.name,
      groupId: state.groupId,
      nodes: state.nodes,
      edges: state.edges,
      selectedNodeId: state.selectedNodeId,
      selectedEdgeId: state.selectedEdgeId,
      connectingNodeId: null,
      connectingPortKey: null,
      isDirty: state.isDirty,
      lastSavedAt: state.lastSavedAt,
    );
  }
  
  void addEdge(String sourceId, String targetId, [String sourcePort = 'output', String targetPort = 'input']) {
    // Prevent duplicates
    if (state.edges.any((e) => 
       e.sourceNodeId == sourceId && 
       e.targetNodeId == targetId &&
       e.sourcePort == sourcePort &&
       e.targetPort == targetPort
    )) {
        return;
    }
    state = state.copyWith(edges: [...state.edges, WorkflowEdge(
      sourceNodeId: sourceId, 
      targetNodeId: targetId,
      sourcePort: sourcePort,
      targetPort: targetPort
    )], isDirty: true);
  }
}

final workflowEditorProvider = StateNotifierProvider<WorkflowEditorController, WorkflowEditorState>((ref) {
  final repository = ref.watch(workflowRepositoryProvider);
  return WorkflowEditorController(repository);
});
