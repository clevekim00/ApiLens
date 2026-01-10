import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/workflow_node.dart';
import '../domain/models/workflow_edge.dart';

class WorkflowEditorState {
  final String id;
  final String name;
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final String? selectedNodeId;
  final String? connectingNodeId;
  final String? connectingPortKey;

  const WorkflowEditorState({
    required this.id,
    this.name = 'Untitled Workflow',
    this.nodes = const [],
    this.edges = const [],
    this.selectedNodeId,
    this.connectingNodeId,
    this.connectingPortKey,
  });

  WorkflowEditorState copyWith({
    String? id,
    String? name,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
    String? selectedNodeId,
    String? connectingNodeId,
    String? connectingPortKey,
  }) {
    return WorkflowEditorState(
      id: id ?? this.id,
      name: name ?? this.name,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      selectedNodeId: selectedNodeId ?? this.selectedNodeId,
      connectingNodeId: connectingNodeId ?? this.connectingNodeId,
      connectingPortKey: connectingPortKey ?? this.connectingPortKey,
    );
  }
}

class WorkflowEditorController extends StateNotifier<WorkflowEditorState> {
  WorkflowEditorController() : super(WorkflowEditorState(
    id: const Uuid().v4(),
    nodes: [
        WorkflowNode(id: 'start', type: 'start', x: 100, y: 100),
    ],
  ));
  
  void loadWorkflow(String id, String name, List<WorkflowNode> nodes, List<WorkflowEdge> edges) {
    state = WorkflowEditorState(id: id, name: name, nodes: nodes, edges: edges);
  }
  
  void clearWorkflow() {
    state = WorkflowEditorState(
      id: const Uuid().v4(),
      nodes: [WorkflowNode(id: 'start', type: 'start', x: 100, y: 100)],
    );
  }
  
  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void addNode(WorkflowNode node) {
    state = state.copyWith(nodes: [...state.nodes, node]);
  }

  void updateNodePosition(String id, double dx, double dy) {
    state = state.copyWith(
      nodes: state.nodes.map((n) {
        if (n.id == id) {
          return WorkflowNode(
              id: n.id,
              type: n.type,
              x: n.x + dx,
              y: n.y + dy,
              data: n.data,
              inputPortKeys: n.inputPortKeys,
              outputPortKeys: n.outputPortKeys);
        }
        return n;
      }).toList(),
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
    );
  }

  void selectNode(String? id) {
    if (state.connectingNodeId != null) {
      cancelConnection();
    }
    // Direct constructor to allow nullifying selectedNodeId safely
    // copyWith with 'id' param would work if we trust null handling, 
    // but explicit constructor is safest when dealing with clearing fields.
    state = WorkflowEditorState(
      id: state.id,
      name: state.name,
      nodes: state.nodes,
      edges: state.edges,
      selectedNodeId: id,
      connectingNodeId: state.connectingNodeId,
      connectingPortKey: state.connectingPortKey,
    );
  }

  void deleteNode(String id) {
    // Cascade delete edges
    final newEdges = state.edges.where((e) => e.sourceNodeId != id && e.targetNodeId != id).toList();
    final newNodes = state.nodes.where((n) => n.id != id).toList();
    state = WorkflowEditorState(
      id: state.id,
      name: state.name,
      nodes: newNodes,
      edges: newEdges,
      selectedNodeId: state.selectedNodeId == id ? null : state.selectedNodeId,
      connectingNodeId: state.connectingNodeId,
      connectingPortKey: state.connectingPortKey,
    );
  }

  // Connection Logic
  void startConnection(String nodeId, String portKey) {
    state = WorkflowEditorState(
      id: state.id,
      name: state.name,
      nodes: state.nodes,
      edges: state.edges,
      selectedNodeId: state.selectedNodeId,
      connectingNodeId: nodeId,
      connectingPortKey: portKey,
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
      nodes: state.nodes,
      edges: state.edges,
      selectedNodeId: state.selectedNodeId,
      connectingNodeId: null,
      connectingPortKey: null,
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
    )]);
  }
}

final workflowEditorProvider = StateNotifierProvider<WorkflowEditorController, WorkflowEditorState>((ref) {
  return WorkflowEditorController();
});
