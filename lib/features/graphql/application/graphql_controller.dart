import 'dart:convert';

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
  final String? variablesValidationError;
  final bool isSchemaLoading;
  final String? schemaError;
  final Map<String, dynamic>? schema;
  final String schemaSearchQuery;
  final String? selectedSchemaTypeName;

  GraphQLState({
    required this.activeConfig,
    this.lastResponse,
    this.isLoading = false,
    this.error,
    this.variablesValidationError,
    this.isSchemaLoading = false,
    this.schemaError,
    this.schema,
    this.schemaSearchQuery = '',
    this.selectedSchemaTypeName,
  });

  GraphQLState copyWith({
    GraphQLRequestConfig? activeConfig,
    GraphQLResponse? lastResponse,
    bool? isLoading,
    String? error,
    String? variablesValidationError,
    bool? isSchemaLoading,
    String? schemaError,
    Map<String, dynamic>? schema,
    String? schemaSearchQuery,
    String? selectedSchemaTypeName,
    bool clearLastResponse = false,
    bool clearError = false,
    bool clearVariablesValidationError = false,
    bool clearSchemaError = false,
    bool clearSchema = false,
    bool clearSelectedSchemaType = false,
  }) {
    return GraphQLState(
      activeConfig: activeConfig ?? this.activeConfig,
      lastResponse:
          clearLastResponse ? null : lastResponse ?? this.lastResponse,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      variablesValidationError: clearVariablesValidationError
          ? null
          : variablesValidationError ?? this.variablesValidationError,
      isSchemaLoading: isSchemaLoading ?? this.isSchemaLoading,
      schemaError: clearSchemaError ? null : schemaError ?? this.schemaError,
      schema: clearSchema ? null : schema ?? this.schema,
      schemaSearchQuery: schemaSearchQuery ?? this.schemaSearchQuery,
      selectedSchemaTypeName: clearSelectedSchemaType
          ? null
          : selectedSchemaTypeName ?? this.selectedSchemaTypeName,
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
    state = state.copyWith(
      activeConfig: state.activeConfig.copyWith(endpoint: endpoint),
      clearError: true,
    );
  }

  void updateQuery(String query) {
    state = state.copyWith(
      activeConfig: state.activeConfig.copyWith(query: query),
      clearError: true,
    );
  }

  void updateVariables(String json) {
    final validationError = validateVariablesJson(json);
    state = state.copyWith(
      activeConfig: state.activeConfig.copyWith(variablesJson: json),
      variablesValidationError: validationError,
      clearVariablesValidationError: validationError == null,
      clearError: true,
    );
  }

  void formatVariablesJson() {
    final source = state.activeConfig.variablesJson.trim();
    if (source.isEmpty) {
      updateVariables('{}');
      return;
    }

    final validationError = validateVariablesJson(source);
    if (validationError != null) {
      state = state.copyWith(
        variablesValidationError: validationError,
        error: validationError,
      );
      return;
    }

    final formatted = const JsonEncoder.withIndent('  ').convert(
      jsonDecode(source),
    );
    state = state.copyWith(
      activeConfig: state.activeConfig.copyWith(variablesJson: formatted),
      clearVariablesValidationError: true,
      clearError: true,
    );
  }

  void updateAuth(Map<String, dynamic> auth) {
    state =
        state.copyWith(activeConfig: state.activeConfig.copyWith(auth: auth));
  }

  void updateHeaders(Map<String, String> headers) {
    state = state.copyWith(
        activeConfig: state.activeConfig.copyWith(headers: headers));
  }

  void setSchemaSearchQuery(String query) {
    state = state.copyWith(schemaSearchQuery: query);
  }

  void selectSchemaType(String? typeName) {
    state = state.copyWith(
      selectedSchemaTypeName: typeName,
      clearSelectedSchemaType: typeName == null,
    );
  }

  // Actions
  Future<void> executeRequest() async {
    final validationError =
        validateVariablesJson(state.activeConfig.variablesJson);
    if (validationError != null) {
      state = state.copyWith(
        isLoading: false,
        error: validationError,
        variablesValidationError: validationError,
        clearLastResponse: true,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearLastResponse: true,
      clearVariablesValidationError: true,
    );

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

  Future<void> fetchSchema() async {
    if (state.activeConfig.endpoint.trim().isEmpty) {
      state = state.copyWith(
        schemaError: 'Enter a GraphQL endpoint before fetching schema.',
      );
      return;
    }

    state = state.copyWith(
      isSchemaLoading: true,
      clearSchemaError: true,
      clearSchema: true,
      clearSelectedSchemaType: true,
    );

    try {
      final schema = await _service.introspectSchema(state.activeConfig);
      final types = _schemaTypes(schema);
      final firstTypeName =
          types.isEmpty ? null : types.first['name']?.toString();
      state = state.copyWith(
        isSchemaLoading: false,
        schema: schema,
        selectedSchemaTypeName: firstTypeName,
      );
    } catch (e) {
      state = state.copyWith(
        isSchemaLoading: false,
        schemaError: e.toString(),
      );
    }
  }

  Future<void> loadRequest(String id) async {
    final config = await _repository.get(id);
    if (config != null) {
      final validationError = validateVariablesJson(config.variablesJson);
      state = state.copyWith(
        activeConfig: config,
        variablesValidationError: validationError,
        clearVariablesValidationError: validationError == null,
        clearLastResponse: true,
        clearError: true,
        clearSchema: true,
        clearSchemaError: true,
        clearSelectedSchemaType: true,
      );
    }
  }

  void clearRequest() {
    state = state.copyWith(
        activeConfig: GraphQLRequestConfig(
            id: const Uuid().v4(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now()),
        clearLastResponse: true,
        clearError: true,
        clearVariablesValidationError: true,
        clearSchema: true,
        clearSchemaError: true,
        clearSelectedSchemaType: true);
  }
}

List<Map<String, dynamic>> graphQLSchemaTypes(GraphQLState state) {
  final schema = state.schema;
  if (schema == null) return const [];

  final query = state.schemaSearchQuery.trim().toLowerCase();
  final types = _schemaTypes(schema).where((type) {
    final name = (type['name'] ?? '').toString();
    if (name.startsWith('__')) return false;
    if (query.isEmpty) return true;

    final kind = (type['kind'] ?? '').toString();
    final description = (type['description'] ?? '').toString();
    return name.toLowerCase().contains(query) ||
        kind.toLowerCase().contains(query) ||
        description.toLowerCase().contains(query);
  }).toList()
    ..sort((a, b) => (a['name'] ?? '').toString().compareTo(
          (b['name'] ?? '').toString(),
        ));

  return types;
}

Map<String, dynamic>? selectedGraphQLSchemaType(GraphQLState state) {
  final types = graphQLSchemaTypes(state);
  if (types.isEmpty) return null;

  final selectedName = state.selectedSchemaTypeName;
  if (selectedName != null) {
    for (final type in types) {
      if (type['name'] == selectedName) return type;
    }
  }

  return types.first;
}

List<Map<String, dynamic>> _schemaTypes(Map<String, dynamic> schema) {
  final rawTypes = schema['types'];
  if (rawTypes is! List) return const [];
  return rawTypes.whereType<Map>().map((type) {
    return type.map((key, value) => MapEntry(key.toString(), value));
  }).toList();
}

String? validateVariablesJson(String source) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) return null;

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) return null;
    if (decoded is Map) return null;

    return 'Variables must be a JSON object, for example { "id": "1" }.';
  } on FormatException catch (error) {
    return 'Invalid variables JSON: ${error.message}';
  } catch (_) {
    return 'Invalid variables JSON.';
  }
}

final graphQLControllerProvider =
    StateNotifierProvider<GraphQLController, GraphQLState>((ref) {
  final repo = ref.watch(graphQLRepositoryProvider);
  final service = ref.watch(graphQLServiceProvider);
  return GraphQLController(repo, service);
});
