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
  late final ExecutionEngine _engine;

  WorkflowRunnerController() : super(const WorkflowRunnerState()) {
    _engine = ExecutionEngine(onLog: _handleLog);
  }

  void _handleLog(String message) {
    if (mounted) {
      state = state.copyWith(logs: [...state.logs, message]);
    }
  }

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
  // We need to defer controller creation or move logs handling but 
  // ExecutionEngine needs a callback. 
  // Since Controller holds the state, we can't easily pass "controller.addLog" to constructor BEFORE controller exists.
  // Instead, let's create the engine inside the controller or pass a dummy and set it later?
  // Easier: Pass a closure that delegates to a specialized "LogManager" or just pass null and let Controller attach?
  // BUT ExecutionEngine doesn't expose a "setListener".
  // 
  // Better approach:
  // Controller creates the engine.
  // Or we change the architecture slightly. 
  // 
  // Let's make Controller create the Engine with 'this' reference? No.
  // 
  // Let's define the callback to use the ref.notifier AFTER generic setup?
  // No, Provider doesn't work that way easily.
  //
  // Simpler: Inside WorkflowRunnerController, we initialize the engine.
  return WorkflowRunnerController(); 
});
