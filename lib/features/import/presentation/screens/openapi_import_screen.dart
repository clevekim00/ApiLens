import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/components/app_button.dart';
import '../../../../core/ui/components/app_card.dart';
import '../../../../core/ui/components/app_empty_state.dart';
import '../../../../core/ui/components/app_input.dart';
import '../../../../core/ui/components/app_status_chip.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import '../../application/openapi_import_controller.dart';
import '../../domain/models/openapi_operation_model.dart';

class OpenApiImportScreen extends ConsumerStatefulWidget {
  final String targetGroupId;

  const OpenApiImportScreen({super.key, required this.targetGroupId});

  @override
  ConsumerState<OpenApiImportScreen> createState() =>
      _OpenApiImportScreenState();
}

class _OpenApiImportScreenState extends ConsumerState<OpenApiImportScreen> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleFilePick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'yaml', 'yml'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final String content;
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        return;
      }

      ref.read(openApiImportControllerProvider.notifier).loadContent(content);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File Error: $error')),
      );
    }
  }

  Future<void> _handleUrlLoad() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    await ref.read(openApiImportControllerProvider.notifier).loadFromUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(openApiImportControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('OpenAPI Specification Import'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -90,
            right: -90,
            child: _AmbientBlob(size: 280),
          ),
          SafeArea(
            child: state.parseResult == null
                ? _ImportLandingPanel(
                    urlController: _urlController,
                    isLoading: state.isLoading,
                    error: state.error,
                    onFilePick: _handleFilePick,
                    onUrlLoad: _handleUrlLoad,
                  )
                : _ParsedImportWorkspace(state: state),
          ),
        ],
      ),
      bottomNavigationBar: state.parseResult == null
          ? null
          : _ImportBottomBar(
              state: state,
              targetGroupId: widget.targetGroupId,
            ),
    );
  }
}

class _ImportLandingPanel extends StatelessWidget {
  final TextEditingController urlController;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onFilePick;
  final Future<void> Function() onUrlLoad;

  const _ImportLandingPanel({
    required this.urlController,
    required this.isLoading,
    required this.error,
    required this.onFilePick,
    required this.onUrlLoad,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.s5),
        child: AppCard(
          width: 560,
          padding: const EdgeInsets.all(AppTokens.s6),
          backgroundColor: theme.cardColor.withValues(alpha: 0.88),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.s4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  size: 46,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppTokens.s5),
              Text(
                'Start Your Integration',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppTokens.s2),
              Text(
                'Paste a Swagger URL or upload a spec file to preview endpoints before import.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: AppTokens.s6),
              AppInput(
                controller: urlController,
                hintText: 'Swagger UI or JSON/YAML URL',
                prefixIcon: const Icon(Icons.link, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: isLoading ? null : onUrlLoad,
                ),
                onSubmitted: (_) => onUrlLoad(),
              ),
              const SizedBox(height: AppTokens.s5),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppTokens.s4),
                    child: Text(
                      'OR',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.54),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppTokens.s5),
              AppButton(
                label: 'Choose Spec File',
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                onPressed: isLoading ? null : onFilePick,
                width: double.infinity,
              ),
              if (isLoading) ...[
                const SizedBox(height: AppTokens.s5),
                const CircularProgressIndicator(),
              ],
              if (error != null) ...[
                const SizedBox(height: AppTokens.s5),
                _InlineError(message: error!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ParsedImportWorkspace extends ConsumerWidget {
  final OpenApiImportState state;

  const _ParsedImportWorkspace({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(openApiImportControllerProvider.notifier);
    final allTags = _extractAllTags(state.parseResult!.operations);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 880;
        final phone = constraints.maxWidth < 520;

        return Padding(
          padding: EdgeInsets.all(compact ? AppTokens.s3 : AppTokens.s4),
          child: phone
              ? ListView(
                  key: const ValueKey('openapi_import_workspace_compact'),
                  children: [
                    SizedBox(
                      height: 104,
                      child: _TagFilterList(
                        activeTags: state.activeTags,
                        allTags: allTags,
                        onToggle: controller.toggleTag,
                        compact: true,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s3),
                    SizedBox(
                      height: 360,
                      child: _OperationTablePanel(state: state),
                    ),
                    const SizedBox(height: AppTokens.s3),
                    SizedBox(
                      height: 360,
                      child: _OperationPreviewPanel(state: state),
                    ),
                  ],
                )
              : compact
                  ? Column(
                      key: const ValueKey('openapi_import_workspace_compact'),
                      children: [
                        SizedBox(
                          height: 112,
                          child: _TagFilterList(
                            activeTags: state.activeTags,
                            allTags: allTags,
                            onToggle: controller.toggleTag,
                            compact: true,
                          ),
                        ),
                        const SizedBox(height: AppTokens.s3),
                        Expanded(
                          flex: 6,
                          child: _OperationTablePanel(state: state),
                        ),
                        const SizedBox(height: AppTokens.s3),
                        Expanded(
                          flex: 5,
                          child: _OperationPreviewPanel(state: state),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('openapi_import_workspace'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 256,
                          child: _TagFilterList(
                            activeTags: state.activeTags,
                            allTags: allTags,
                            onToggle: controller.toggleTag,
                          ),
                        ),
                        const SizedBox(width: AppTokens.s3),
                        Expanded(
                          flex: 7,
                          child: _OperationTablePanel(state: state),
                        ),
                        const SizedBox(width: AppTokens.s3),
                        SizedBox(
                          width: 380,
                          child: _OperationPreviewPanel(state: state),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}

class _TagFilterList extends StatelessWidget {
  final Set<String> activeTags;
  final Set<String> allTags;
  final ValueChanged<String> onToggle;
  final bool compact;

  const _TagFilterList({
    required this.activeTags,
    required this.allTags,
    required this.onToggle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTags = allTags.toList()..sort();

    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: compact
          ? Padding(
              padding: const EdgeInsets.all(AppTokens.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PanelTitle(
                    icon: Icons.sell_outlined,
                    title: 'Tags',
                    subtitle: activeTags.isEmpty
                        ? 'All endpoints'
                        : '${activeTags.length} active',
                  ),
                  const SizedBox(height: AppTokens.s2),
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _TagChip(
                          label: 'All',
                          selected: activeTags.isEmpty,
                          onSelected: () => onToggle('ALL'),
                        ),
                        ...sortedTags.map(
                          (tag) => _TagChip(
                            label: tag,
                            selected: activeTags.contains(tag),
                            onSelected: () => onToggle(tag),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(AppTokens.s4),
                  child: _PanelTitle(
                    icon: Icons.sell_outlined,
                    title: 'Filter by Tags',
                    subtitle: 'Scope the import list',
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s2,
                    ),
                    children: [
                      CheckboxListTile(
                        title: const Text('All Endpoints'),
                        value: activeTags.isEmpty,
                        onChanged: (_) => onToggle('ALL'),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusMd),
                        ),
                      ),
                      const Divider(height: 1),
                      ...sortedTags.map(
                        (tag) => CheckboxListTile(
                          title: Text(
                            tag,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          value: activeTags.contains(tag),
                          onChanged: (_) => onToggle(tag),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusMd),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTokens.s2),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _OperationTablePanel extends ConsumerWidget {
  final OpenApiImportState state;

  const _OperationTablePanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(openApiImportControllerProvider.notifier);
    final parseResult = state.parseResult;

    return DecoratedBox(
      key: const ValueKey('openapi_operation_table'),
      decoration: _panelDecoration(context),
      child: Column(
        children: [
          _SpecTableHeader(
            title: _specTitle(parseResult),
            version: _specVersion(parseResult),
            baseUrl: parseResult?.baseUrl,
            operationCount: parseResult?.operations.length ?? 0,
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Padding(
            padding: const EdgeInsets.all(AppTokens.s3),
            child: Column(
              children: [
                _OperationSearchInput(
                  value: state.searchQuery,
                  onChanged: controller.setSearchQuery,
                ),
                const SizedBox(height: AppTokens.s2),
                _OperationTableToolbar(
                  shownCount: state.visibleOperations.length,
                  selectedCount: state.selectedOperationIds.length,
                  onToggleAll: controller.toggleSelectAllFiltered,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: state.visibleOperations.isEmpty
                ? const AppEmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No endpoints match',
                    message: 'Adjust tag filters or search terms.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: AppTokens.s2),
                    itemCount: state.visibleOperations.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: AppTokens.s5,
                      color: Theme.of(context).dividerColor,
                    ),
                    itemBuilder: (context, index) {
                      final operation = state.visibleOperations[index];
                      return _OperationTableRow(
                        operation: operation,
                        selected: state.selectedOperationIds.contains(
                          operation.id,
                        ),
                        previewed: state.previewOperationId == operation.id,
                        onPreview: () =>
                            controller.selectPreviewOperation(operation.id),
                        onToggle: () =>
                            controller.toggleOperation(operation.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SpecTableHeader extends StatelessWidget {
  final String title;
  final String version;
  final String? baseUrl;
  final int operationCount;

  const _SpecTableHeader({
    required this.title,
    required this.version,
    required this.baseUrl,
    required this.operationCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppTokens.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppTokens.s2,
            runSpacing: AppTokens.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              AppStatusChip(
                label: version,
                dense: true,
                tone: AppStatusTone.info,
              ),
              AppStatusChip(
                label: '$operationCount ops',
                dense: true,
                tone: AppStatusTone.neutral,
              ),
            ],
          ),
          if (baseUrl != null && baseUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: AppTokens.s1),
            Text(
              baseUrl!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.monoStyle.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OperationSearchInput extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _OperationSearchInput({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_OperationSearchInput> createState() => _OperationSearchInputState();
}

class _OperationSearchInputState extends State<_OperationSearchInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _OperationSearchInput oldWidget) {
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
      hintText: 'Search path, method, summary, operationId...',
      prefixIcon: const Icon(Icons.search_rounded, size: 18),
      onChanged: widget.onChanged,
    );
  }
}

class _OperationTableToolbar extends StatelessWidget {
  final int shownCount;
  final int selectedCount;
  final VoidCallback onToggleAll;

  const _OperationTableToolbar({
    required this.shownCount,
    required this.selectedCount,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final selectButton = AppButton(
          label: compact ? 'Select' : 'Select visible',
          icon: const Icon(Icons.checklist_rounded, size: 16),
          onPressed: shownCount == 0 ? null : onToggleAll,
          variant: AppButtonVariant.ghost,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
        );
        final counts = Wrap(
          spacing: AppTokens.s1,
          runSpacing: AppTokens.s1,
          alignment: WrapAlignment.end,
          children: [
            AppStatusChip(
              label: '$shownCount shown',
              tone: AppStatusTone.neutral,
              dense: true,
            ),
            AppStatusChip(
              label: '$selectedCount selected',
              tone: selectedCount == 0
                  ? AppStatusTone.neutral
                  : AppStatusTone.info,
              dense: true,
            ),
          ],
        );

        return Row(
          children: [
            selectButton,
            const Spacer(),
            Flexible(child: counts),
          ],
        );
      },
    );
  }
}

class _OperationTableRow extends StatelessWidget {
  final OpenApiOperation operation;
  final bool selected;
  final bool previewed;
  final VoidCallback onPreview;
  final VoidCallback onToggle;

  const _OperationTableRow({
    required this.operation,
    required this.selected,
    required this.previewed,
    required this.onPreview,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final rowColor = previewed
            ? theme.colorScheme.primary.withValues(alpha: 0.075)
            : Colors.transparent;

        return Material(
          color: rowColor,
          child: InkWell(
            onTap: onPreview,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s3,
                vertical: AppTokens.s2,
              ),
              child: Row(
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (_) => onToggle(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    ),
                  ),
                  const SizedBox(width: AppTokens.s1),
                  Expanded(
                    child: compact
                        ? _CompactOperationSummary(operation: operation)
                        : _WideOperationSummary(operation: operation),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: AppTokens.s3),
                    _MetricPill(
                      icon: Icons.tune_outlined,
                      label: '${operation.parameters.length}',
                    ),
                    const SizedBox(width: AppTokens.s2),
                    _MetricPill(
                      icon: Icons.lock_outline,
                      label: '${operation.security.length}',
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WideOperationSummary extends StatelessWidget {
  final OpenApiOperation operation;

  const _WideOperationSummary({required this.operation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = operation.summary ?? operation.operationId ?? '';

    return Row(
      children: [
        SizedBox(width: 70, child: _MethodBadge(method: operation.method)),
        const SizedBox(width: AppTokens.s3),
        Expanded(
          flex: 3,
          child: Text(
            operation.path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTokens.monoStyle.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.s3),
        Expanded(
          flex: 2,
          child: Text(
            subtitle.isEmpty ? 'No summary' : subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactOperationSummary extends StatelessWidget {
  final OpenApiOperation operation;

  const _CompactOperationSummary({required this.operation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = operation.summary ?? operation.operationId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppTokens.s2,
          runSpacing: AppTokens.s1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MethodBadge(method: operation.method),
            Text(
              operation.path,
              style: AppTokens.monoStyle.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: AppTokens.s1),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
            ),
          ),
        ],
        const SizedBox(height: AppTokens.s1),
        Wrap(
          spacing: AppTokens.s1,
          runSpacing: AppTokens.s1,
          children: [
            _MetricPill(
              icon: Icons.tune_outlined,
              label: '${operation.parameters.length} params',
            ),
            _MetricPill(
              icon: Icons.lock_outline,
              label: '${operation.security.length} auth',
            ),
          ],
        ),
      ],
    );
  }
}

class _OperationPreviewPanel extends StatelessWidget {
  final OpenApiImportState state;

  const _OperationPreviewPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final operation = selectedOpenApiPreviewOperation(state);

    return DecoratedBox(
      key: const ValueKey('openapi_operation_preview'),
      decoration: _panelDecoration(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final denseHeader = constraints.maxHeight < 240;

          return DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTokens.s4,
                    denseHeader ? AppTokens.s1 : AppTokens.s3,
                    AppTokens.s4,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!denseHeader) ...[
                        const _PanelTitle(
                          icon: Icons.preview_outlined,
                          title: 'Preview',
                          subtitle: 'Inspect before importing',
                        ),
                        const SizedBox(height: AppTokens.s3),
                      ],
                      const TabBar(
                        tabs: [
                          Tab(text: 'Operation'),
                          Tab(text: 'Options'),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                Expanded(
                  child: TabBarView(
                    children: [
                      operation == null
                          ? const AppEmptyState(
                              icon: Icons.touch_app_outlined,
                              title: 'Pick an operation',
                              message:
                                  'Select a row to preview request details.',
                            )
                          : _OperationPreviewContent(operation: operation),
                      _ImportOptionsPanel(options: state.options),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OperationPreviewContent extends StatelessWidget {
  final OpenApiOperation operation;

  const _OperationPreviewContent({required this.operation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = operation.description ?? operation.summary;

    return ListView(
      padding: const EdgeInsets.all(AppTokens.s4),
      children: [
        Wrap(
          spacing: AppTokens.s2,
          runSpacing: AppTokens.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MethodBadge(method: operation.method),
            AppStatusChip(
              label: operation.operationId ?? 'no operationId',
              dense: true,
              tone: AppStatusTone.neutral,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s3),
        Text(
          operation.path,
          style: AppTokens.monoStyle.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (description != null && description.trim().isNotEmpty) ...[
          const SizedBox(height: AppTokens.s3),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
            ),
          ),
        ],
        const SizedBox(height: AppTokens.s4),
        _PreviewStatGrid(operation: operation),
        const SizedBox(height: AppTokens.s4),
        _PreviewSection(
          title: 'Tags',
          child: operation.tags.isEmpty
              ? const Text('Untagged')
              : Wrap(
                  spacing: AppTokens.s1,
                  runSpacing: AppTokens.s1,
                  children: operation.tags
                      .map(
                        (tag) => AppStatusChip(
                          label: tag,
                          dense: true,
                          tone: AppStatusTone.info,
                        ),
                      )
                      .toList(),
                ),
        ),
        _PreviewSection(
          title: 'Parameters',
          child: _JsonPreviewBlock(value: operation.parameters),
        ),
        _PreviewSection(
          title: 'Request Body',
          child: _JsonPreviewBlock(value: operation.requestBody),
        ),
        _PreviewSection(
          title: 'Security',
          child: _JsonPreviewBlock(value: operation.security),
        ),
      ],
    );
  }
}

class _PreviewStatGrid extends StatelessWidget {
  final OpenApiOperation operation;

  const _PreviewStatGrid({required this.operation});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTokens.s2,
      runSpacing: AppTokens.s2,
      children: [
        _PreviewStatCard(
          label: 'Parameters',
          value: '${operation.parameters.length}',
          icon: Icons.tune_outlined,
        ),
        _PreviewStatCard(
          label: 'Auth Rules',
          value: '${operation.security.length}',
          icon: Icons.lock_outline,
        ),
        _PreviewStatCard(
          label: 'Body',
          value: operation.requestBody == null ? 'No' : 'Yes',
          icon: Icons.data_object_outlined,
        ),
      ],
    );
  }
}

class _PreviewStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _PreviewStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 104,
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.045),
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(height: AppTokens.s2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _PreviewSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppTokens.s2),
          child,
        ],
      ),
    );
  }
}

class _JsonPreviewBlock extends StatelessWidget {
  final dynamic value;

  const _JsonPreviewBlock({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = value == null ||
        (value is List && value.isEmpty) ||
        (value is Map && value.isEmpty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.035),
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Text(
        empty ? 'None' : _prettyJson(value),
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
        style: AppTokens.monoStyle.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ImportOptionsPanel extends ConsumerWidget {
  final ImportOptions options;

  const _ImportOptionsPanel({required this.options});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update =
        ref.read(openApiImportControllerProvider.notifier).updateOptions;

    return ListView(
      padding: const EdgeInsets.all(AppTokens.s4),
      children: [
        _OptionSection(
          title: 'Base URL',
          children: [
            _RadioOption<BaseUrlBehavior>(
              title: 'Use {{env.baseUrl}}',
              subtitle: 'Recommended for reusable imported requests.',
              value: BaseUrlBehavior.env,
              groupValue: options.baseUrlBehavior,
              onChanged: (value) => update(
                options.copyWith(baseUrlBehavior: value),
              ),
            ),
            _RadioOption<BaseUrlBehavior>(
              title: 'Use fixed URL from spec',
              subtitle: 'Keep the server URL directly in generated requests.',
              value: BaseUrlBehavior.fixed,
              groupValue: options.baseUrlBehavior,
              onChanged: (value) => update(
                options.copyWith(baseUrlBehavior: value),
              ),
            ),
          ],
        ),
        _OptionSection(
          title: 'Request Body',
          children: [
            _RadioOption<BodySampleStrategy>(
              title: 'Prefer examples',
              subtitle: 'Use OpenAPI examples when available.',
              value: BodySampleStrategy.example,
              groupValue: options.bodySampleStrategy,
              onChanged: (value) => update(
                options.copyWith(bodySampleStrategy: value),
              ),
            ),
            _RadioOption<BodySampleStrategy>(
              title: 'Schema based',
              subtitle: 'Generate a sample from schema shape.',
              value: BodySampleStrategy.schema,
              groupValue: options.bodySampleStrategy,
              onChanged: (value) => update(
                options.copyWith(bodySampleStrategy: value),
              ),
            ),
            _RadioOption<BodySampleStrategy>(
              title: 'Minimal {}',
              subtitle: 'Create empty JSON bodies only.',
              value: BodySampleStrategy.minimal,
              groupValue: options.bodySampleStrategy,
              onChanged: (value) => update(
                options.copyWith(bodySampleStrategy: value),
              ),
            ),
          ],
        ),
        _OptionSection(
          title: 'Duplicates',
          children: [
            _RadioOption<DuplicateBehavior>(
              title: 'Skip existing',
              subtitle: 'Avoid overwriting matching saved requests.',
              value: DuplicateBehavior.skip,
              groupValue: options.duplicateBehavior,
              onChanged: (value) => update(
                options.copyWith(duplicateBehavior: value),
              ),
            ),
            _RadioOption<DuplicateBehavior>(
              title: 'Rename',
              subtitle: 'Create a unique name for duplicates.',
              value: DuplicateBehavior.rename,
              groupValue: options.duplicateBehavior,
              onChanged: (value) => update(
                options.copyWith(duplicateBehavior: value),
              ),
            ),
            _RadioOption<DuplicateBehavior>(
              title: 'Create new',
              subtitle: 'Always import selected operations.',
              value: DuplicateBehavior.createNew,
              groupValue: options.duplicateBehavior,
              onChanged: (value) => update(
                options.copyWith(duplicateBehavior: value),
              ),
            ),
          ],
        ),
        _OptionSection(
          title: 'Authentication',
          children: [
            _RadioOption<AuthBehavior>(
              title: 'Auto detect',
              subtitle: 'Import auth metadata where possible.',
              value: AuthBehavior.detect,
              groupValue: options.authBehavior,
              onChanged: (value) => update(
                options.copyWith(authBehavior: value),
              ),
            ),
            _RadioOption<AuthBehavior>(
              title: 'Ignore',
              subtitle: 'Leave auth empty in generated requests.',
              value: AuthBehavior.ignore,
              groupValue: options.authBehavior,
              onChanged: (value) => update(
                options.copyWith(authBehavior: value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _OptionSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppTokens.s2),
          ...children,
        ],
      ),
    );
  }
}

class _RadioOption<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;

  const _RadioOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = value == groupValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s2),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s3),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.07)
                : theme.colorScheme.onSurface.withValues(alpha: 0.025),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.dividerColor,
            ),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: Row(
            children: [
              _RadioMark(selected: selected),
              const SizedBox(width: AppTokens.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  final bool selected;

  const _RadioMark({required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.36);

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: selected ? 5 : 1.5),
      ),
    );
  }
}

class _ImportBottomBar extends ConsumerWidget {
  final OpenApiImportState state;
  final String targetGroupId;

  const _ImportBottomBar({
    required this.state,
    required this.targetGroupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s4,
        AppTokens.s3,
        AppTokens.s4,
        AppTokens.s3,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 920;
            final importDisabled =
                state.selectedOperationIds.isEmpty || state.isLoading;
            final details = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.selectedOperationIds.length} operations selected',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Target folder: $targetGroupId',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                  ),
                ),
              ],
            );

            final resetButton = AppButton(
              label: compact ? 'Reset' : 'Reset Spec',
              icon: const Icon(Icons.refresh, size: 16),
              onPressed: () => ref
                  .read(openApiImportControllerProvider.notifier)
                  .loadContent(
                    '',
                  ),
              variant: AppButtonVariant.ghost,
            );
            final workflowButton = AppButton(
              label: compact ? 'Workflow' : 'Create Workflow',
              icon: const Icon(Icons.account_tree_outlined, size: 16),
              onPressed:
                  importDisabled ? null : () => _createWorkflow(context, ref),
              variant: AppButtonVariant.outline,
            );
            final importButton = AppButton(
              label: compact ? 'Import' : 'Import Requests',
              icon: const Icon(Icons.download_rounded, size: 16),
              onPressed:
                  importDisabled ? null : () => _importRequests(context, ref),
            );

            if (compact) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: AppTokens.s3),
                  Row(
                    children: [
                      Expanded(child: resetButton),
                      const SizedBox(width: AppTokens.s2),
                      Expanded(child: workflowButton),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s2),
                  importButton,
                ],
              );
            }

            return Row(
              children: [
                details,
                const Spacer(),
                resetButton,
                const SizedBox(width: AppTokens.s2),
                workflowButton,
                const SizedBox(width: AppTokens.s2),
                importButton,
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _createWorkflow(BuildContext context, WidgetRef ref) async {
    final name =
        'Workflow ${DateTime.now().toLocal().toString().split('.')[0]}';
    final workflowId = await ref
        .read(openApiImportControllerProvider.notifier)
        .generateWorkflowFromSelected(name, targetGroupId);

    if (!context.mounted) return;
    if (workflowId != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Workflow Generated'),
          content: const Text(
            'Successfully generated workflow from selected endpoints.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate workflow.')),
      );
    }
  }

  Future<void> _importRequests(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(openApiImportControllerProvider.notifier)
        .importSelected(targetGroupId);

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Complete'),
        content:
            Text('Success: ${result['success']}\nErrors: ${result['error']}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
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
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.56),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final String method;

  const _MethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    final color = _methodColor(method);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s2,
        vertical: AppTokens.s1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        method.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s2,
        vertical: AppTokens.s1,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
          ),
          const SizedBox(width: AppTokens.s1),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.24),
        ),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: AppTokens.s2),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientBlob extends StatelessWidget {
  final double size;

  const _AmbientBlob({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      ),
    );
  }
}

Set<String> _extractAllTags(List<OpenApiOperation> operations) {
  final tags = <String>{};
  for (final operation in operations) {
    if (operation.tags.isEmpty) {
      tags.add('(Untagged)');
    } else {
      tags.addAll(operation.tags);
    }
  }
  return tags;
}

String _specTitle(OpenApiParseResult? result) {
  final title = result?.info['title']?.toString();
  if (title == null || title.trim().isEmpty) return 'OpenAPI Specification';
  return title;
}

String _specVersion(OpenApiParseResult? result) {
  final version = result?.info['version']?.toString();
  if (version == null || version.trim().isEmpty) return 'unversioned';
  return 'v$version';
}

String _prettyJson(dynamic value) {
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value.toString();
  }
}

BoxDecoration _panelDecoration(BuildContext context) {
  final theme = Theme.of(context);

  return BoxDecoration(
    color: theme.cardColor,
    border: Border.all(color: theme.dividerColor),
    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
  );
}

Color _methodColor(String method) {
  switch (method.toUpperCase()) {
    case 'GET':
      return Colors.green;
    case 'POST':
      return Colors.orange;
    case 'PUT':
      return Colors.blue;
    case 'PATCH':
      return Colors.indigo;
    case 'DELETE':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
