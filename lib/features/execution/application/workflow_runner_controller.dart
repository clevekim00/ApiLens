import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workflow_editor/domain/models/workflow_node.dart';
import '../../workflow_editor/domain/models/workflow_edge.dart'; // Fixed import path
import '../domain/models/execution_models.dart';
import 'execution_engine.dart';

class WorkflowRunnerState {
  final bool isRunning;
  final Map<String, NodeRunResult> results;
  final List<String> logs; // Simple log list

  const WorkflowRunnerState({
    this.isRunning = false,
    this.results = const {},
    this.logs = const [],
  });

  WorkflowRunnerState copyWith({
    bool? isRunning,
    Map<String, NodeRunResult>? results,
    List<String>? logs,
  }) {
    return WorkflowRunnerState(
      isRunning: isRunning ?? this.isRunning,
      results: results ?? this.results,
      logs: logs ?? this.logs,
    );
  }
}

class WorkflowRunnerController extends StateNotifier<WorkflowRunnerState> {
  final ExecutionEngine _engine;

  WorkflowRunnerController(this._engine) : super(const WorkflowRunnerState());

  void clear() {
    state = const WorkflowRunnerState();
  }

  Future<void> run(List<WorkflowNode> nodes, List<WorkflowEdge> edges) async {
    if (state.isRunning) return;

    clear();
    state = state.copyWith(isRunning: true, logs: ['Execution started...']);

    await for (final result in _engine.runWorkflow(nodes, edges)) {
      final newResults = Map<String, NodeRunResult>.from(state.results);
      newResults[result.nodeId] = result;
      
      final msg = '[${result.nodeId}] ${result.status.name.toUpperCase()}';
      
      state = state.copyWith(
        results: newResults,
        logs: [...state.logs, msg],
      );
      
      if (result.status == NodeStatus.failure) {
         state = state.copyWith(logs: [...state.logs, 'Execution failed: ${result.errorMessage}']);
      }
    }

    state = state.copyWith(isRunning: false, logs: [...state.logs, 'Execution finished.']);
  }
}

final workflowRunnerProvider = StateNotifierProvider<WorkflowRunnerController, WorkflowRunnerState>((ref) {
  return WorkflowRunnerController(ExecutionEngine());
});
