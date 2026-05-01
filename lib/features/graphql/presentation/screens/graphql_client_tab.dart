import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/response_model.dart';
import '../../../../core/ui/components/app_button.dart';
import '../../../../core/ui/components/app_input.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import '../../../response/widgets/response_viewer.dart';
import '../../application/graphql_controller.dart';
import '../../domain/models/graphql_response.dart';
import '../widgets/graphql_editors.dart';

class GraphQLClientTab extends ConsumerStatefulWidget {
  const GraphQLClientTab({super.key});

  @override
  ConsumerState<GraphQLClientTab> createState() => _GraphQLClientTabState();
}

class _GraphQLClientTabState extends ConsumerState<GraphQLClientTab> {
  static const double _sideBySideBreakpoint = 900;

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

    if (_endpointController.text != state.activeConfig.endpoint) {
      _endpointController.text = state.activeConfig.endpoint;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideBySide = constraints.maxWidth >= _sideBySideBreakpoint;

        return ColoredBox(
          color: _workspaceBackground(context),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EndpointBar(
                  endpointController: _endpointController,
                  isLoading: state.isLoading,
                  onEndpointChanged: controller.updateEndpoint,
                  onExecute: controller.executeRequest,
                  onClear: controller.clearRequest,
                ),
                const SizedBox(height: AppTokens.s3),
                Expanded(
                  child: useSideBySide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _EditorPanel(
                                state: state,
                                onQueryChanged: controller.updateQuery,
                                onVariablesChanged: controller.updateVariables,
                              ),
                            ),
                            const SizedBox(width: AppTokens.s3),
                            Expanded(
                              flex: 5,
                              child: _GraphQLResponsePanel(state: state),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(
                              flex: 6,
                              child: _EditorPanel(
                                state: state,
                                onQueryChanged: controller.updateQuery,
                                onVariablesChanged: controller.updateVariables,
                              ),
                            ),
                            const SizedBox(height: AppTokens.s3),
                            Expanded(
                              flex: 5,
                              child: _GraphQLResponsePanel(state: state),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EndpointBar extends StatelessWidget {
  final TextEditingController endpointController;
  final bool isLoading;
  final ValueChanged<String> onEndpointChanged;
  final VoidCallback onExecute;
  final VoidCallback onClear;

  const _EndpointBar({
    required this.endpointController,
    required this.isLoading,
    required this.onEndpointChanged,
    required this.onExecute,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;
            final input = AppInput(
              controller: endpointController,
              hintText: 'GraphQL endpoint (https://...)',
              prefixIcon: const Icon(Icons.hub_outlined, size: 18),
              onChanged: onEndpointChanged,
            );
            final executeButton = AppButton(
              label: isLoading ? 'Executing...' : 'Execute',
              icon: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow, size: 16),
              onPressed: isLoading ? null : onExecute,
              variant: AppButtonVariant.primary,
            );
            final clearButton = AppButton(
              label: 'Clear',
              icon: const Icon(Icons.refresh, size: 16),
              onPressed: onClear,
              variant: AppButtonVariant.ghost,
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  input,
                  const SizedBox(height: AppTokens.s2),
                  Row(
                    children: [
                      Expanded(child: executeButton),
                      const SizedBox(width: AppTokens.s2),
                      clearButton,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: input),
                const SizedBox(width: AppTokens.s2),
                executeButton,
                const SizedBox(width: AppTokens.s1),
                clearButton,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  final GraphQLState state;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onVariablesChanged;

  const _EditorPanel({
    required this.state,
    required this.onQueryChanged,
    required this.onVariablesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const _PanelHeader(
              icon: Icons.code_outlined,
              title: 'GraphQL Document',
              subtitle: 'Query and variables',
              trailing: SizedBox(
                width: 220,
                child: TabBar(
                  tabs: [
                    Tab(text: 'Query'),
                    Tab(text: 'Variables'),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            Expanded(
              child: TabBarView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTokens.s3),
                    child: GraphQLQueryEditor(
                      query: state.activeConfig.query,
                      onChanged: onQueryChanged,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppTokens.s3),
                    child: GraphQLVariablesEditor(
                      variables: state.activeConfig.variablesJson,
                      onChanged: onVariablesChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphQLResponsePanel extends StatelessWidget {
  final GraphQLState state;

  const _GraphQLResponsePanel({required this.state});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        child: _buildResponseArea(context, state),
      ),
    );
  }

  Widget _buildResponseArea(BuildContext context, GraphQLState state) {
    if (state.isLoading) {
      return const _GraphQLInlineState(
        icon: Icons.sync,
        title: 'Executing query...',
        message: 'Waiting for GraphQL response.',
        loading: true,
      );
    }

    if (state.error != null) {
      return _GraphQLErrorState(error: state.error!);
    }

    if (state.lastResponse != null) {
      return ResponseViewer(response: _toResponseModel(state.lastResponse!));
    }

    return const _GraphQLInlineState(
      icon: Icons.play_circle_outline,
      title: 'Ready to execute',
      message: 'Run a query to inspect GraphQL data and errors here.',
    );
  }

  ResponseModel _toResponseModel(GraphQLResponse gql) {
    return ResponseModel(
      statusCode: gql.statusCode,
      statusMessage: gql.isSuccess ? 'OK' : 'Error',
      headers: const {},
      body: gql.rawText,
      jsonBody: gql.data ?? {'errors': gql.errors},
      durationMs: gql.durationMs,
      sizeBytes: gql.rawText.length,
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s3,
        vertical: AppTokens.s2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _GraphQLInlineState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool loading;

  const _GraphQLInlineState({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              Icon(
                icon,
                size: 36,
                color: theme.colorScheme.primary.withValues(alpha: 0.62),
              ),
            const SizedBox(height: AppTokens.s3),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTokens.s1),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphQLErrorState extends StatelessWidget {
  final String error;

  const _GraphQLErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppTokens.s4),
        padding: const EdgeInsets.all(AppTokens.s4),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withValues(alpha: 0.10),
          border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: AppTokens.s2),
            Flexible(
              child: Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration(BuildContext context) {
  final theme = Theme.of(context);

  return BoxDecoration(
    color: theme.colorScheme.surface,
    border: Border.all(color: theme.dividerColor),
    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
  );
}

Color _workspaceBackground(BuildContext context) {
  final theme = Theme.of(context);
  return Color.alphaBlend(
    theme.colorScheme.primary.withValues(alpha: 0.025),
    theme.scaffoldBackgroundColor,
  );
}
