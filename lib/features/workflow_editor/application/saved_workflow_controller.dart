import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/workflow_repository.dart';
import '../domain/models/workflow.dart';
import '../domain/models/workflow_node.dart';
import '../domain/models/workflow_edge.dart';

class SavedWorkflowController extends StateNotifier<List<Workflow>> {
  final WorkflowRepository _repository;

  SavedWorkflowController(this._repository) : super([]) {
    refresh();
  }

  Future<void> refresh() async {
    state = await _repository.getAll();
  }

  Future<void> deleteWorkflow(String id) async {
    await _repository.delete(id);
    await refresh();
  }

  // Method to be called after saving from Editor
  void notifySaved() {
    refresh();
  }

  Future<String> createWorkflow({
    required String name,
    required String groupId,
    List<WorkflowNode>? nodes,
    List<WorkflowEdge>? edges,
  }) async {
    final workflowId = const Uuid().v4();

    final finalNodes = nodes ??
        [
          WorkflowNode(id: const Uuid().v4(), type: 'start', x: 100, y: 200),
          WorkflowNode(id: const Uuid().v4(), type: 'end', x: 500, y: 200),
        ];

    final finalEdges = edges ?? [];

    final workflow = Workflow(
      id: workflowId,
      name: name,
      groupId: groupId,
      nodes: finalNodes,
      edges: finalEdges,
      lastModified: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.save(workflow);
    await refresh();
    return workflowId;
  }
}

final savedWorkflowControllerProvider =
    StateNotifierProvider<SavedWorkflowController, List<Workflow>>((ref) {
  final repo = ref.watch(workflowRepositoryProvider);
  return SavedWorkflowController(repo);
});
