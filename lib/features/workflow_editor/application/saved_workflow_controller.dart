import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/workflow_repository.dart';
import '../domain/models/workflow.dart';

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
}

final savedWorkflowControllerProvider = StateNotifierProvider<SavedWorkflowController, List<Workflow>>((ref) {
  final repo = ref.watch(workflowRepositoryProvider);
  return SavedWorkflowController(repo);
});
