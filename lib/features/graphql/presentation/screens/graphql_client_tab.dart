import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:apilens/core/ui/components/app_button.dart';
import 'package:apilens/features/graphql/application/graphql_controller.dart';
import 'package:apilens/features/graphql/presentation/widgets/graphql_editors.dart';
import 'package:apilens/features/response/widgets/response_viewer.dart';
import 'package:apilens/core/ui/components/app_input.dart';
import 'package:apilens/core/network/models/response_model.dart';
import 'package:apilens/features/graphql/domain/models/graphql_response.dart';

class GraphQLClientTab extends ConsumerStatefulWidget {
  const GraphQLClientTab({super.key});

  @override
  ConsumerState<GraphQLClientTab> createState() => _GraphQLClientTabState();
}

class _GraphQLClientTabState extends ConsumerState<GraphQLClientTab> {
  late TextEditingController _endpointController;

  @override
  void initState() {
    super.initState();
    _endpointController = TextEditingController();
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(graphQLControllerProvider);
    final controller = ref.read(graphQLControllerProvider.notifier);

    // Sync controller if needed, but avoid loops. 
    // Ideally, we only set it once or if the state changes externally (e.g. load request).
    // For now simple approach: if text differs, update it.
    if (_endpointController.text != state.activeConfig.endpoint) {
       _endpointController.text = state.activeConfig.endpoint;
    }

    return Column(
      children: [
        // 1. Endpoint Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: AppInput(
                   controller: _endpointController,
                   hintText: 'GraphQL Endpoint (https://...)',
                   onChanged: controller.updateEndpoint,
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: 'Execute',
                icon: const Icon(Icons.play_arrow, size: 16),
                onPressed: state.isLoading ? null : controller.executeRequest,
                variant: AppButtonVariant.primary,
              ),
            ],
          ),
        ),

        // 2. Main Content Split
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Editors
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                     // Query Editor
                     Expanded(
                       flex: 2,
                       child: Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Query', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Expanded(
                                child: GraphQLQueryEditor(
                                  query: state.activeConfig.query,
                                  onChanged: controller.updateQuery,
                                ),
                              ),
                            ],
                         ),
                       ),
                     ),
                     // Variables Editor
                     Expanded(
                       flex: 1,
                       child: Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Variables (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Expanded(
                                child: GraphQLVariablesEditor(
                                  variables: state.activeConfig.variablesJson,
                                  onChanged: controller.updateVariables,
                                ),
                              ),
                            ],
                         ),
                       ),
                     ),
                  ],
                ),
              ),
              
              const VerticalDivider(width: 1),

              // Right: Response
              Expanded(
                flex: 1,
                child: _buildResponseArea(state),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponseArea(GraphQLState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.error != null) {
      return Center(child: Text('Error: ${state.error}', style: const TextStyle(color: Colors.red)));
    }

    if (state.lastResponse != null) {
      // Convert GraphQLResponse to ResponseModel
      final gql = state.lastResponse!;
      final responseModel = ResponseModel(
        statusCode: gql.statusCode,
        statusMessage: gql.isSuccess ? 'OK' : 'Error',
        headers: {}, // Not captured yet
        body: gql.rawText ?? '', // Ensure non-null
        jsonBody: gql.data ?? {'errors': gql.errors},
        durationMs: gql.durationMs,
        sizeBytes: (gql.rawText?.length ?? 0),
      );

      return ResponseViewer(response: responseModel);
    }

    return const Center(child: Text('Ready to execute', style: TextStyle(color: Colors.grey)));
  }
}
