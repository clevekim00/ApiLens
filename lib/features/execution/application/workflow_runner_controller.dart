import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workflow_editor/domain/models/workflow_node.dart';
import '../../workflow_editor/domain/models/workflow_edge.dart'; // Fixed import path
import '../domain/models/execution_models.dart';
import 'execution_engine.dart';
import '../../../core/network/websocket/websocket_manager.dart';

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

final workflowRunnerProvider = StateNotifierProvider<WorkflowRunnerController, WorkflowRunnerState>((ref) {
  // Inject WebSocketManager
  final wsManager = ref.watch(webSocketManagerProvider);
  return WorkflowRunnerController(wsManager: wsManager);
});

class WorkflowRunnerController extends StateNotifier<WorkflowRunnerState> {
  final WebSocketManager _wsManager;
  WorkflowRunnerController({required WebSocketManager wsManager}) 
    : _wsManager = wsManager,
      super(const WorkflowRunnerState());

  StreamSubscription? _subscription;

  void clear() {
    state = const WorkflowRunnerState();
  }

  Future<void> run(List<WorkflowNode> nodes, List<WorkflowEdge> edges) async {
    if (state.isRunning) return;

    clear();
    state = state.copyWith(isRunning: true, logs: ['Execution started...']);

    // Instantiate engine per run to maintain fresh state (like activeConnectionId)
    final engine = ExecutionEngine(
      wsManager: _wsManager,
      onLog: (msg) {
        if (mounted) {
           state = state.copyWith(logs: [...state.logs, msg]);
        }
      }
    );

    await for (final result in engine.runWorkflow(nodes, edges)) {
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


