import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../workflow_editor/domain/models/workflow_node.dart';
import '../../workflow_editor/domain/models/workflow_edge.dart'; // Fixed import path
import '../domain/models/execution_models.dart';
import 'execution_engine.dart';
import '../../../core/network/websocket/websocket_manager.dart';
import '../../../core/network/graphql_service.dart';

class WorkflowRunnerState {
  final bool isRunning;
  final Map<String, NodeRunResult> results;
  final Map<String, bool> traversedEdgeIds; // edgeId -> isError
  final List<String> logs;

  const WorkflowRunnerState({
    this.isRunning = false,
    this.results = const {},
    this.traversedEdgeIds = const {},
    this.logs = const [],
  });

  WorkflowRunnerState copyWith({
    bool? isRunning,
    Map<String, NodeRunResult>? results,
    Map<String, bool>? traversedEdgeIds,
    List<String>? logs,
  }) {
    return WorkflowRunnerState(
      isRunning: isRunning ?? this.isRunning,
      results: results ?? this.results,
      traversedEdgeIds: traversedEdgeIds ?? this.traversedEdgeIds,
      logs: logs ?? this.logs,
    );
  }
}

final workflowRunnerProvider =
    StateNotifierProvider<WorkflowRunnerController, WorkflowRunnerState>((ref) {
  // Inject WebSocketManager
  final wsManager = ref.watch(webSocketManagerProvider);
  final gqlService = ref.watch(graphQLServiceProvider);
  return WorkflowRunnerController(wsManager: wsManager, gqlService: gqlService);
});

class WorkflowRunnerController extends StateNotifier<WorkflowRunnerState> {
  final WebSocketManager _wsManager;
  final GraphQLService _gqlService;

  WorkflowRunnerController(
      {required WebSocketManager wsManager, required GraphQLService gqlService})
      : _wsManager = wsManager,
        _gqlService = gqlService,
        super(const WorkflowRunnerState());

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
        gqlService: _gqlService,
        onLog: (msg) {
          if (mounted) {
            state = state.copyWith(logs: [...state.logs, msg]);
          }
        });

    await for (final event in engine.runWorkflow(nodes, edges)) {
      if (event is NodeExecutionEvent) {
        final result = event.result;
        final newResults = Map<String, NodeRunResult>.from(state.results);
        newResults[result.nodeId] = result;

        final msg = '[${result.nodeId}] ${result.status.name.toUpperCase()}';

        state = state.copyWith(
          results: newResults,
          logs: [...state.logs, msg],
        );

        if (result.status == NodeStatus.failure) {
          state = state.copyWith(logs: [
            ...state.logs,
            'Execution failed: ${result.errorMessage}'
          ]);
        }
      } else if (event is EdgeExecutionEvent) {
        final newEdges = Map<String, bool>.from(state.traversedEdgeIds);
        newEdges[event.edgeId] = event.isError;
        state = state.copyWith(traversedEdgeIds: newEdges);
      }
    }

    state = state.copyWith(
        isRunning: false, logs: [...state.logs, 'Execution finished.']);
  }
}
