import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/response_model.dart';
import '../../../../core/ui/components/app_button.dart';
import '../../../../core/ui/components/app_empty_state.dart';
import '../../../../core/ui/components/app_input.dart';
import '../../../../core/ui/components/app_split_pane.dart';
import '../../../../core/ui/components/app_status_chip.dart';
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
                  validationError: state.variablesValidationError,
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
                                onFormatVariables:
                                    controller.formatVariablesJson,
                                onFetchSchema: controller.fetchSchema,
                                onSchemaSearchChanged:
                                    controller.setSchemaSearchQuery,
                                onSchemaTypeSelected:
                                    controller.selectSchemaType,
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
                                onFormatVariables:
                                    controller.formatVariablesJson,
                                onFetchSchema: controller.fetchSchema,
                                onSchemaSearchChanged:
                                    controller.setSchemaSearchQuery,
                                onSchemaTypeSelected:
                                    controller.selectSchemaType,
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
  final String? validationError;
  final ValueChanged<String> onEndpointChanged;
  final VoidCallback onExecute;
  final VoidCallback onClear;

  const _EndpointBar({
    required this.endpointController,
    required this.isLoading,
    required this.validationError,
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
              onPressed:
                  isLoading || validationError != null ? null : onExecute,
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
                  if (validationError != null) ...[
                    const SizedBox(height: AppTokens.s2),
                    _ValidationBadge(message: validationError!),
                  ],
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
                if (validationError != null) ...[
                  const SizedBox(width: AppTokens.s2),
                  Flexible(child: _ValidationBadge(message: validationError!)),
                ],
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
  final VoidCallback onFormatVariables;
  final VoidCallback onFetchSchema;
  final ValueChanged<String> onSchemaSearchChanged;
  final ValueChanged<String?> onSchemaTypeSelected;

  const _EditorPanel({
    required this.state,
    required this.onQueryChanged,
    required this.onVariablesChanged,
    required this.onFormatVariables,
    required this.onFetchSchema,
    required this.onSchemaSearchChanged,
    required this.onSchemaTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const _PanelHeader(
              icon: Icons.code_outlined,
              title: 'GraphQL Document',
              subtitle: 'Query, variables, and schema',
              trailing: SizedBox(
                width: 320,
                child: TabBar(
                  tabs: [
                    Tab(text: 'Query'),
                    Tab(text: 'Variables'),
                    Tab(text: 'Schema'),
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
                      validationError: state.variablesValidationError,
                      onChanged: onVariablesChanged,
                      onFormat: onFormatVariables,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppTokens.s3),
                    child: _SchemaExplorerPanel(
                      state: state,
                      onFetchSchema: onFetchSchema,
                      onSearchChanged: onSchemaSearchChanged,
                      onTypeSelected: onSchemaTypeSelected,
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

class _SchemaExplorerPanel extends StatelessWidget {
  final GraphQLState state;
  final VoidCallback onFetchSchema;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onTypeSelected;

  const _SchemaExplorerPanel({
    required this.state,
    required this.onFetchSchema,
    required this.onSearchChanged,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (state.schema == null &&
        !state.isSchemaLoading &&
        state.schemaError == null) {
      return AppEmptyState(
        icon: Icons.schema_outlined,
        title: 'Schema explorer',
        message:
            'Fetch the endpoint schema to browse types, fields, arguments, and enums.',
        action: AppButton(
          label: 'Fetch schema',
          icon: const Icon(Icons.cloud_download_outlined, size: 16),
          onPressed: onFetchSchema,
          variant: AppButtonVariant.primary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SchemaToolbar(
          state: state,
          onFetchSchema: onFetchSchema,
          onSearchChanged: onSearchChanged,
        ),
        const SizedBox(height: AppTokens.s3),
        Expanded(
          child: _buildSchemaBody(context),
        ),
      ],
    );
  }

  Widget _buildSchemaBody(BuildContext context) {
    if (state.isSchemaLoading) {
      return const AppEmptyState(
        icon: Icons.sync,
        title: 'Fetching schema...',
        message: 'Running GraphQL introspection against the active endpoint.',
      );
    }

    if (state.schemaError != null) {
      return AppEmptyState(
        icon: Icons.error_outline,
        title: 'Schema fetch failed',
        message: state.schemaError!,
        action: AppButton(
          label: 'Retry',
          icon: const Icon(Icons.refresh, size: 16),
          onPressed: onFetchSchema,
        ),
      );
    }

    final types = graphQLSchemaTypes(state);
    final selectedType = selectedGraphQLSchemaType(state);
    if (types.isEmpty || selectedType == null) {
      return const AppEmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'No matching schema types',
        message: 'Try a different schema search term.',
      );
    }

    return AppSplitPane(
      breakpoint: 760,
      primaryFlex: 4,
      secondaryFlex: 5,
      primary: _SchemaTypeList(
        types: types,
        selectedName: selectedType['name']?.toString(),
        onTypeSelected: onTypeSelected,
      ),
      secondary: _SchemaTypePreview(type: selectedType),
    );
  }
}

class _SchemaToolbar extends StatelessWidget {
  final GraphQLState state;
  final VoidCallback onFetchSchema;
  final ValueChanged<String> onSearchChanged;

  const _SchemaToolbar({
    required this.state,
    required this.onFetchSchema,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalTypes = graphQLSchemaTypes(
      state.copyWith(schemaSearchQuery: ''),
    ).length;
    final visibleTypes = graphQLSchemaTypes(state).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final search = _SchemaSearchField(
          value: state.schemaSearchQuery,
          hintText: 'Search schema types',
          onChanged: onSearchChanged,
        );
        final fetch = AppButton(
          label: state.isSchemaLoading ? 'Fetching...' : 'Fetch schema',
          icon: state.isSchemaLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_download_outlined, size: 16),
          onPressed: state.isSchemaLoading ? null : onFetchSchema,
        );
        final count = AppStatusChip(
          label: '$visibleTypes / $totalTypes types',
          icon: Icons.schema_outlined,
          tone: AppStatusTone.info,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: AppTokens.s2),
              Row(
                children: [
                  count,
                  const Spacer(),
                  fetch,
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: AppTokens.s2),
            count,
            const SizedBox(width: AppTokens.s2),
            fetch,
          ],
        );
      },
    );
  }
}

class _SchemaSearchField extends StatefulWidget {
  final String value;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _SchemaSearchField({
    required this.value,
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<_SchemaSearchField> createState() => _SchemaSearchFieldState();
}

class _SchemaSearchFieldState extends State<_SchemaSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SchemaSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: _controller,
      hintText: widget.hintText,
      prefixIcon: const Icon(Icons.search, size: 18),
      onChanged: widget.onChanged,
    );
  }
}

class _SchemaTypeList extends StatelessWidget {
  final List<Map<String, dynamic>> types;
  final String? selectedName;
  final ValueChanged<String?> onTypeSelected;

  const _SchemaTypeList({
    required this.types,
    required this.selectedName,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: ListView.separated(
        itemCount: types.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: theme.dividerColor),
        itemBuilder: (context, index) {
          final type = types[index];
          final name = type['name']?.toString() ?? '(anonymous)';
          final kind = type['kind']?.toString() ?? 'TYPE';
          final selected = selectedName == name;

          return ListTile(
            selected: selected,
            dense: true,
            title: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
            subtitle: Text(kind),
            trailing: _fieldCountChip(type),
            onTap: () => onTypeSelected(name),
          );
        },
      ),
    );
  }

  Widget _fieldCountChip(Map<String, dynamic> type) {
    final count = _schemaMembers(type).length;
    return AppStatusChip(
      label: '$count',
      dense: true,
      tone: AppStatusTone.neutral,
    );
  }
}

class _SchemaTypePreview extends StatelessWidget {
  final Map<String, dynamic> type;

  const _SchemaTypePreview({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = _schemaMembers(type);

    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTokens.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppTokens.s2,
                  runSpacing: AppTokens.s1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      type['name']?.toString() ?? '(anonymous)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    AppStatusChip(
                      label: type['kind']?.toString() ?? 'TYPE',
                      dense: true,
                      tone: AppStatusTone.info,
                    ),
                  ],
                ),
                if ((type['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: AppTokens.s2),
                  Text(
                    type['description'].toString(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.70),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: members.isEmpty
                ? const AppEmptyState(
                    icon: Icons.short_text_outlined,
                    title: 'No members',
                    message:
                        'This schema type does not expose fields, inputs, or enum values.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTokens.s3),
                    itemCount: members.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTokens.s2),
                    itemBuilder: (context, index) {
                      return _SchemaMemberCard(member: members[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SchemaMemberCard extends StatelessWidget {
  final Map<String, dynamic> member;

  const _SchemaMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args =
        (member['args'] as List?)?.whereType<Map>().toList() ?? const [];

    return Container(
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.025),
          theme.colorScheme.surface,
        ),
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                member['name']?.toString() ?? '(member)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              AppStatusChip(
                label: _typeLabel(member['type']),
                dense: true,
                tone: AppStatusTone.neutral,
              ),
              if (member['isDeprecated'] == true)
                const AppStatusChip(
                  label: 'deprecated',
                  dense: true,
                  tone: AppStatusTone.warning,
                ),
            ],
          ),
          if ((member['description'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: AppTokens.s1),
            Text(
              member['description'].toString(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
          ],
          if (args.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s2),
            Wrap(
              spacing: AppTokens.s1,
              runSpacing: AppTokens.s1,
              children: args.map((arg) {
                return AppStatusChip(
                  label: '${arg['name']}: ${_typeLabel(arg['type'])}',
                  dense: true,
                  tone: AppStatusTone.info,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _schemaMembers(Map<String, dynamic> type) {
  final fields = type['fields'];
  if (fields is List && fields.isNotEmpty) {
    return fields.whereType<Map>().map(_stringKeyedMap).toList();
  }

  final inputFields = type['inputFields'];
  if (inputFields is List && inputFields.isNotEmpty) {
    return inputFields.whereType<Map>().map(_stringKeyedMap).toList();
  }

  final enumValues = type['enumValues'];
  if (enumValues is List && enumValues.isNotEmpty) {
    return enumValues.whereType<Map>().map(_stringKeyedMap).toList();
  }

  return const [];
}

Map<String, dynamic> _stringKeyedMap(Map<dynamic, dynamic> value) {
  return value.map((key, dynamic item) => MapEntry(key.toString(), item));
}

String _typeLabel(dynamic rawType) {
  if (rawType is! Map) return 'value';

  final kind = rawType['kind']?.toString();
  final name = rawType['name']?.toString();
  final nestedType = rawType['ofType'];
  final nestedLabel = nestedType is Map ? _typeLabel(nestedType) : null;

  if (kind == 'NON_NULL') return '${nestedLabel ?? name ?? 'value'}!';
  if (kind == 'LIST') return '[${nestedLabel ?? name ?? 'value'}]';
  if (name != null && name.isNotEmpty) return name;
  return nestedLabel ?? kind ?? 'value';
}

class _ValidationBadge extends StatelessWidget {
  final String message;

  const _ValidationBadge({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s2,
        vertical: AppTokens.s1,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.24),
        ),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 15, color: theme.colorScheme.error),
          const SizedBox(width: AppTokens.s1),
          Flexible(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
