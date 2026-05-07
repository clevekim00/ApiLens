import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/workflow_node.dart';
import '../domain/models/workflow_edge.dart';

class WorkflowEditorState {
  final String id;
  final String name;
  final String? groupId; // Link to parent folder
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;
  final List<String> selectedNodeIds;
  final String? connectingNodeId;
  final String? connectingPortKey;
  final bool isDirty;
  final DateTime? lastSavedAt;
  final String? selectedEdgeId;
  final Offset viewportCenter;

  const WorkflowEditorState({
    required this.id,
    this.name = 'Untitled Workflow',
    this.groupId,
    this.nodes = const [],
    this.edges = const [],
    this.selectedNodeIds = const [],
    this.connectingNodeId,
    this.connectingPortKey,
    this.isDirty = false,
    this.lastSavedAt,
    this.selectedEdgeId,
    this.viewportCenter =
        const Offset(2500, 2500), // Default center of 5000x5000
  });

  WorkflowEditorState copyWith({
    String? id,
    String? name,
    String? groupId,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
    List<String>? selectedNodeIds,
    String? connectingNodeId,
    String? connectingPortKey,
    bool? isDirty,
    DateTime? lastSavedAt,
    String? selectedEdgeId,
    Offset? viewportCenter,
  }) {
    return WorkflowEditorState(
      id: id ?? this.id,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      connectingPortKey: connectingPortKey ?? this.connectingPortKey,
      isDirty: isDirty ?? this.isDirty,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      selectedEdgeId: selectedEdgeId ?? this.selectedEdgeId,
      connectingNodeId: connectingNodeId ?? this.connectingNodeId,
      viewportCenter: viewportCenter ?? this.viewportCenter,
    );
  }
}

class WorkflowEditorController extends StateNotifier<WorkflowEditorState> {
  WorkflowEditorController()
      : super(WorkflowEditorState(
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

  void loadWorkflow(String id, String name, List<WorkflowNode> nodes,
      List<WorkflowEdge> edges,
      {String? groupId}) {
    state = WorkflowEditorState(
        id: id,
        name: name,
        groupId: groupId,
        nodes: nodes,
        edges: edges,
        isDirty: false,
        lastSavedAt: DateTime.now());
  }

  void clearWorkflow() {
    state = WorkflowEditorState(
      id: const Uuid().v4(),
      name: 'Untitled Workflow',
      nodes: [WorkflowNode(id: 'start', type: 'start', x: 100, y: 100)],
      isDirty: false,
    );
  }

  void saveAs(String newId, String newName) {
    state = state.copyWith(
        id: newId, name: newName, isDirty: false, lastSavedAt: DateTime.now());
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
          return n.copyWith(x: x, y: y);
        }
        return n;
      }).toList(),
      isDirty: true,
    );
  }

  void updateViewportCenter(Offset center) {
    state = state.copyWith(viewportCenter: center);
  }

  void updateNodeConfig(String id, Map<String, dynamic> newData) {
    state = state.copyWith(
      nodes: state.nodes.map((n) {
        if (n.id == id) {
          final mergedData = Map<String, dynamic>.from(n.data)..addAll(newData);
          return n.copyWith(data: mergedData);
        }
        return n;
      }).toList(),
      isDirty: true,
    );
  }

  void selectNode(String? id, {bool multi = false}) {
    if (state.connectingNodeId != null) {
      cancelConnection();
    }

    List<String> newSelection;
    if (id == null) {
      newSelection = const [];
    } else if (multi) {
      newSelection = List.from(state.selectedNodeIds);
      if (newSelection.contains(id)) {
        newSelection.remove(id);
      } else {
        newSelection.add(id);
      }
    } else {
      newSelection = [id];
    }

    state = WorkflowEditorState(
      id: state.id,
      name: state.name,
      groupId: state.groupId,
      nodes: state.nodes,
      edges: state.edges,
      selectedNodeIds: newSelection,
      selectedEdgeId: null,
      connectingNodeId: state.connectingNodeId,
      connectingPortKey: state.connectingPortKey,
      isDirty: state.isDirty,
      lastSavedAt: state.lastSavedAt,
      viewportCenter: state.viewportCenter,
    );
  }

  void selectAll() {
    state =
        state.copyWith(selectedNodeIds: state.nodes.map((n) => n.id).toList());
  }

  void selectEdge(String? id) {
    if (state.connectingNodeId != null) cancelConnection();
    state = WorkflowEditorState(
      id: state.id,
      name: state.name,
      groupId: state.groupId,
      nodes: state.nodes,
      edges: state.edges,
      selectedNodeIds: const [], // Clear node selection
      selectedEdgeId: id,
      connectingNodeId: state.connectingNodeId,
      connectingPortKey: state.connectingPortKey,
      isDirty: state.isDirty,
      lastSavedAt: state.lastSavedAt,
      viewportCenter: state.viewportCenter,
    );
  }

  void deleteNode(String id) => deleteNodes([id]);

  void deleteNodes(List<String> ids) {
    if (ids.isEmpty) return;

    final newEdges = state.edges
        .where((e) =>
            !ids.contains(e.sourceNodeId) && !ids.contains(e.targetNodeId))
        .toList();

    final newNodes = state.nodes.where((n) => !ids.contains(n.id)).toList();

    final newSelectedNodes =
        state.selectedNodeIds.where((sid) => !ids.contains(sid)).toList();

    String? newSelectedEdgeForState = state.selectedEdgeId;
    if (newSelectedEdgeForState != null &&
        !newEdges.any((e) => e.id == newSelectedEdgeForState)) {
      newSelectedEdgeForState = null;
    }

    state = WorkflowEditorState(
      id: state.id,
      name: state.name,
      groupId: state.groupId,
      nodes: newNodes,
      edges: newEdges,
      selectedNodeIds: newSelectedNodes,
      selectedEdgeId: newSelectedEdgeForState,
      connectingNodeId: state.connectingNodeId,
      connectingPortKey: state.connectingPortKey,
      isDirty: true,
      lastSavedAt: state.lastSavedAt,
      viewportCenter: state.viewportCenter,
    );
  }

  void duplicateNode(String id) {
    final original = state.nodes.firstWhere((n) => n.id == id,
        orElse: () => WorkflowNode(id: '', type: '', x: 0, y: 0));
    if (original.id.isEmpty) return;

    final newNode = original.copyWith(
      id: const Uuid().v4(),
      x: original.x + 20,
      y: original.y + 20,
    );
    addNode(newNode);
    selectNode(newNode.id);
  }

  void duplicateSelection() {
    if (state.selectedNodeIds.isEmpty) return;

    final List<WorkflowNode> newNodes = [];
    final Map<String, String> idMapping = {};

    for (final id in state.selectedNodeIds) {
      final original = state.nodes.firstWhere((n) => n.id == id);
      final newId = const Uuid().v4();
      idMapping[id] = newId;

      newNodes.add(original.copyWith(
        id: newId,
        x: original.x + 40,
        y: original.y + 40,
      ));
    }

    state = state.copyWith(
      nodes: [...state.nodes, ...newNodes],
      selectedNodeIds: newNodes.map((n) => n.id).toList(),
      isDirty: true,
    );
  }

  void deleteEdge(String edgeId) {
    final newEdges = state.edges.where((e) => e.id != edgeId).toList();
    state = state.copyWith(
        edges: newEdges,
        isDirty: true,
        selectedEdgeId:
            state.selectedEdgeId == edgeId ? null : state.selectedEdgeId);
  }

  // Connection Logic
  void startConnection(String nodeId, String portKey) {
    state = WorkflowEditorState(
      id: state.id,
      name: state.name,
      groupId: state.groupId,
      nodes: state.nodes,
      edges: state.edges,
      selectedNodeIds: state.selectedNodeIds,
      selectedEdgeId: state.selectedEdgeId,
      connectingNodeId: nodeId,
      connectingPortKey: portKey,
      isDirty: state.isDirty,
      lastSavedAt: state.lastSavedAt,
      viewportCenter: state.viewportCenter,
    );
  }

  void completeConnection(String targetNodeId, String targetPortKey) {
    if (state.connectingNodeId == null || state.connectingPortKey == null) {
      return;
    }

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
      selectedNodeIds: state.selectedNodeIds,
      selectedEdgeId: state.selectedEdgeId,
      connectingNodeId: null,
      connectingPortKey: null,
      isDirty: state.isDirty,
      lastSavedAt: state.lastSavedAt,
      viewportCenter: state.viewportCenter,
    );
  }

  void addEdge(String sourceId, String targetId,
      [String sourcePort = 'output', String targetPort = 'input']) {
    // Prevent duplicates
    if (state.edges.any((e) =>
        e.sourceNodeId == sourceId &&
        e.targetNodeId == targetId &&
        e.sourcePort == sourcePort &&
        e.targetPort == targetPort)) {
      return;
    }
    state = state.copyWith(edges: [
      ...state.edges,
      WorkflowEdge(
          sourceNodeId: sourceId,
          targetNodeId: targetId,
          sourcePort: sourcePort,
          targetPort: targetPort)
    ], isDirty: true);
  }

  void toggleNodeCompact(String id) {
    state = state.copyWith(
      nodes: state.nodes.map((n) {
        if (n.id == id) return n.copyWith(isCompact: !n.isCompact);
        return n;
      }).toList(),
      isDirty: true,
    );
  }

  void setAllNodesCompact(bool compact) {
    state = state.copyWith(
      nodes: state.nodes.map((n) => n.copyWith(isCompact: compact)).toList(),
      isDirty: true,
    );
  }
}

final workflowEditorProvider =
    StateNotifierProvider<WorkflowEditorController, WorkflowEditorState>((ref) {
  return WorkflowEditorController();
});
