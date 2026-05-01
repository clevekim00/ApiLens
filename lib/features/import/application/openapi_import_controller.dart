import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../domain/models/openapi_operation_model.dart';
import 'swagger_parser_service.dart';
import '../../request/data/request_repository.dart';
import 'swagger_workflow_generator.dart';
import '../../workflow_editor/data/workflow_repository.dart';
import '../../request/application/saved_request_controller.dart';
import '../../workflow_editor/application/saved_workflow_controller.dart';

class OpenApiImportState {
  final bool isLoading;
  final String? error;
  final OpenApiParseResult? parseResult;
  
  // Filters and Selection
  final Set<String> activeTags; // Empty = All, otherwise specific tags
  final String searchQuery;
  final Set<String> selectedOperationIds;
  
  // Options
  final ImportOptions options;
  
  // Computed (could be getter but keeping simple)
  final List<OpenApiOperation> visibleOperations;

  const OpenApiImportState({
    this.isLoading = false,
    this.error,
    this.parseResult,
    this.activeTags = const {},
    this.searchQuery = '',
    this.selectedOperationIds = const {},
    this.options = const ImportOptions(),
    this.visibleOperations = const [],
  });

  OpenApiImportState copyWith({
    bool? isLoading,
    String? error,
    OpenApiParseResult? parseResult,
    Set<String>? activeTags,
    String? searchQuery,
    Set<String>? selectedOperationIds,
    ImportOptions? options,
    List<OpenApiOperation>? visibleOperations,
  }) {
    return OpenApiImportState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      parseResult: parseResult ?? this.parseResult,
      activeTags: activeTags ?? this.activeTags,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedOperationIds: selectedOperationIds ?? this.selectedOperationIds,
      options: options ?? this.options,
      visibleOperations: visibleOperations ?? this.visibleOperations,
    );
  }
}

class OpenApiImportController extends StateNotifier<OpenApiImportState> {
  final SwaggerParserService _parser;
  final Ref _ref;

  OpenApiImportController(this._ref, this._parser) : super(const OpenApiImportState());

  Future<void> loadContent(String content, {String? baseUrlOverride}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = _parser.parseToResult(content);
      if (result == null) throw Exception('Failed to parse content. Ensure it is a valid OpenAPI JSON spec.');

      state = state.copyWith(
        isLoading: false,
        parseResult: result,
        visibleOperations: result.operations,
        selectedOperationIds: {}, // Reset selection
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadFromUrl(String url) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = Dio();
      final response = await dio.get(url);
      
      String content = response.data is String ? response.data : jsonEncode(response.data);
      String effectiveUrl = url;

      // Check if it's HTML (likely Swagger UI)
      final isHtml = content.trim().startsWith('<!DOCTYPE html>') || 
                     content.toLowerCase().contains('<html');

      if (isHtml) {
        // Discovery Logic 1: Look for spec URL in the HTML (Standard Swagger UI pattern)
        final regex = RegExp(r'''url\s*[:=]\s*["\']([^"\']+)["\']''');
        final match = regex.firstMatch(content);
        
        String? discoveredUrl;
        if (match != null) {
          discoveredUrl = match.group(1);
        } else {
          // Discovery Logic 2: Try common relative paths for SpringDoc/Swagger
          final commonPaths = ['/v3/api-docs', '/v2/api-docs', '/api-docs', '/swagger-resources'];
          final baseUri = Uri.parse(url);
          
          for (final path in commonPaths) {
            try {
               final testUrl = baseUri.resolve(path).toString();
               final testResp = await dio.get(testUrl);
               // If it returns JSON, we found it!
               final testContent = testResp.data is String ? testResp.data : jsonEncode(testResp.data);
               if (testContent.trim().startsWith('{') || testContent.trim().startsWith('[')) {
                  discoveredUrl = testUrl;
                  break;
               }
            } catch (_) {}
          }
        }

        if (discoveredUrl != null) {
           effectiveUrl = Uri.parse(url).resolve(discoveredUrl).toString();
           final specResponse = await dio.get(effectiveUrl);
           content = specResponse.data is String ? specResponse.data : jsonEncode(specResponse.data);
        } else {
           throw Exception('Detected Swagger UI page, but could not find the raw API specification URL.');
        }
      }

      await loadContent(content, baseUrlOverride: effectiveUrl);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load spec: ${e.toString()}');
    }
  }

  void toggleTag(String tag) {
    final currentTags = {...state.activeTags};
    if (tag == 'ALL') {
      currentTags.clear();
    } else {
      if (currentTags.contains(tag)) {
        currentTags.remove(tag);
      } else {
        currentTags.add(tag);
      }
    }
    _applyFilters(newTags: currentTags);
  }

  void setSearchQuery(String query) {
    _applyFilters(newQuery: query);
  }

  void _applyFilters({Set<String>? newTags, String? newQuery}) {
    final tags = newTags ?? state.activeTags;
    final query = newQuery ?? state.searchQuery;
    final operations = state.parseResult?.operations ?? [];

    final filtered = operations.where((op) {
      // Tag Filter
      if (tags.isNotEmpty) {
        if (op.tags.isEmpty) {
           if (!tags.contains('(Untagged)')) return false;
        } else {
           if (!op.tags.any((t) => tags.contains(t))) return false;
        }
      }

      // Search Filter
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final match = op.path.toLowerCase().contains(q) ||
                      op.method.toLowerCase().contains(q) ||
                      (op.summary?.toLowerCase().contains(q) ?? false) ||
                      (op.operationId?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }
      return true;
    }).toList();

    state = state.copyWith(
      activeTags: tags,
      searchQuery: query,
      visibleOperations: filtered,
    );
  }

  void toggleOperation(String id) {
    final selected = {...state.selectedOperationIds};
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    state = state.copyWith(selectedOperationIds: selected);
  }

  void toggleSelectAllFiltered() {
    final visibleIds = state.visibleOperations.map((e) => e.id).toSet();
    final selected = {...state.selectedOperationIds};
    
    // Check if all visible are selected
    final allVisibleSelected = visibleIds.every((id) => selected.contains(id));

    if (allVisibleSelected) {
      selected.removeAll(visibleIds);
    } else {
      selected.addAll(visibleIds);
    }
    state = state.copyWith(selectedOperationIds: selected);
  }

  void updateOptions(ImportOptions options) {
    state = state.copyWith(options: options);
  }

  Future<Map<String, int>> importSelected(String targetGroupId) async {
    // Return stats: {success, skip, error}
    final selectedOps = state.parseResult?.operations
        .where((op) => state.selectedOperationIds.contains(op.id)).toList() ?? [];
    
    if (selectedOps.isEmpty) return {'success': 0, 'skip': 0, 'error': 0};

    state = state.copyWith(isLoading: true);
    int success = 0;
    int error = 0;

    // Use current baseUrl or options
    // To implement Env BaseUrl logic fully, we might need to Ensure the Env Variable exists?
    // User requirement: " ( ) workgroup.env.baseUrl에 저장하고 request는 {{env.baseUrl}} 사용 (기본값) "
    // If selected, we should add 'baseUrl' to the current workgroup's environment/variables if not exists.
    // For now we assume we just generate the Request string "{{env.baseUrl}}..."

    final baseUrl = state.parseResult?.baseUrl ?? '';

    try {
      final repo = _ref.read(requestRepositoryProvider);
      
      for (var op in selectedOps) {
        try {
          final req = _parser.convertOperationToRequest(op, state.options, baseUrl);
          final reqWithGroup = req.copyWith(groupId: targetGroupId);
          
          await repo.save(reqWithGroup);
          success++;
        } catch (_) {
          error++;
        }
      }
      
      // Notify state update
      _ref.read(savedRequestControllerProvider.notifier).refresh();
      
      return {'success': success, 'skip': 0, 'error': error};
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<String?> generateWorkflowFromSelected(String name, String? targetGroupId) async {
    final selectedOps = state.parseResult?.operations
        .where((op) => state.selectedOperationIds.contains(op.id)).toList() ?? [];
    
    if (selectedOps.isEmpty) return null;

    state = state.copyWith(isLoading: true);
    try {
      final baseUrl = state.parseResult?.baseUrl ?? '';
      final generator = SwaggerWorkflowGenerator(parserService: _parser);
      final workflow = generator.generateWorkflow(selectedOps, name, targetGroupId, state.options, baseUrl);
      
      final repo = _ref.read(workflowRepositoryProvider);
      await repo.save(workflow);
      
      // Notify state update
      _ref.read(savedWorkflowControllerProvider.notifier).notifySaved();
      
      return workflow.id;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final openApiImportControllerProvider = StateNotifierProvider.autoDispose<OpenApiImportController, OpenApiImportState>((ref) {
  return OpenApiImportController(ref, SwaggerParserService());
});
