import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/graphql_request_config.dart';
import '../domain/models/graphql_response.dart';
import '../data/graphql_request_repository.dart';
import '../../../core/network/graphql_service.dart';

class GraphQLState {
  final GraphQLRequestConfig activeConfig;
  final GraphQLResponse? lastResponse;
  final bool isLoading;
  final String? error;

  GraphQLState({
    required this.activeConfig,
    this.lastResponse,
    this.isLoading = false,
    this.error,
  });

  GraphQLState copyWith({
    GraphQLRequestConfig? activeConfig,
    GraphQLResponse? lastResponse,
    bool? isLoading,
    String? error,
  }) {
    return GraphQLState(
      activeConfig: activeConfig ?? this.activeConfig,
      lastResponse: lastResponse ?? this.lastResponse,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class GraphQLController extends StateNotifier<GraphQLState> {
  final GraphQLRequestRepository _repository;
  final GraphQLService _service;

  GraphQLController(this._repository, this._service)
      : super(GraphQLState(activeConfig: GraphQLRequestConfig.create()));

  // Configuration Updates
  void updateEndpoint(String endpoint) {
    state = state.copyWith(activeConfig: state.activeConfig.copyWith(endpoint: endpoint));
  }

  void updateQuery(String query) {
    state = state.copyWith(activeConfig: state.activeConfig.copyWith(query: query));
  }

  void updateVariables(String json) {
    state = state.copyWith(activeConfig: state.activeConfig.copyWith(variablesJson: json));
  }

  void updateAuth(Map<String, dynamic> auth) {
    state = state.copyWith(activeConfig: state.activeConfig.copyWith(auth: auth));
  }

  void updateHeaders(Map<String, String> headers) {
    state = state.copyWith(activeConfig: state.activeConfig.copyWith(headers: headers));
  }

  // Actions
  Future<void> executeRequest() async {
    state = state.copyWith(isLoading: true, error: null, lastResponse: null);
    
    try {
      final response = await _service.execute(state.activeConfig);
      state = state.copyWith(isLoading: false, lastResponse: response);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveRequest() async {
    await _repository.save(state.activeConfig);
  }

  Future<void> loadRequest(String id) async {
    final config = await _repository.get(id);
    if (config != null) {
      state = state.copyWith(activeConfig: config, lastResponse: null, error: null);
    }
  }

  void clearRequest() {
    state = state.copyWith(
        activeConfig: GraphQLRequestConfig(
            id: const Uuid().v4(), 
            createdAt: DateTime.now(), 
            updatedAt: DateTime.now()
        ),
        lastResponse: null,
        error: null
    );
  }
}

final graphQLControllerProvider = StateNotifierProvider<GraphQLController, GraphQLState>((ref) {
  final repo = ref.watch(graphQLRepositoryProvider);
  final service = ref.watch(graphQLServiceProvider);
  return GraphQLController(repo, service);
});
