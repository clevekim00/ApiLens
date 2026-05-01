import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/models/response_model.dart';
import '../../../core/ui/tokens/app_tokens.dart';
import '../../response/providers/response_provider.dart';
import 'response_compare_dialog.dart';

class ResponseViewer extends ConsumerWidget {
  final ResponseModel? response;

  const ResponseViewer({super.key, this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responseState = response != null
        ? AsyncValue.data(response)
        : ref.watch(responseNotifierProvider);

    return responseState.when(
      data: (response) {
        if (response == null) {
          return const _EmptyResponseState();
        }
        return _ResponseContent(response: response);
      },
      loading: () => const _ResponseLoadingState(),
      error: (err, stack) => _ResponseErrorState(error: err),
    );
  }
}

class _ResponseContent extends StatelessWidget {
  final ResponseModel response;

  const _ResponseContent({required this.response});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResponseSummaryBar(response: response),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      theme.colorScheme.primary.withValues(alpha: 0.025),
                      theme.colorScheme.surface,
                    ),
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      const Tab(text: 'Body'),
                      Tab(text: 'Headers (${response.headers.length})'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ResponseBodyTab(response: response),
                      _ResponseHeadersTab(response: response),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponseSummaryBar extends StatelessWidget {
  final ResponseModel response;

  const _ResponseSummaryBar({required this.response});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(response);

    return Container(
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          statusColor.withValues(alpha: 0.08),
          theme.colorScheme.surface,
        ),
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Wrap(
        spacing: AppTokens.s2,
        runSpacing: AppTokens.s2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              border: Border.all(color: statusColor.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              '${response.statusCode} ${response.statusMessage}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _ResponseMetricChip(
            icon: Icons.timer_outlined,
            label: '${response.durationMs} ms',
          ),
          _ResponseMetricChip(
            icon: Icons.data_object_outlined,
            label: _formatSize(response.sizeBytes),
          ),
          _ResponseMetricChip(
            icon: Icons.notes_outlined,
            label: '${response.headers.length} headers',
          ),
          if (response.jsonBody != null)
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) =>
                      ResponseCompareDialog(currentJson: response.jsonBody),
                );
              },
              icon: const Icon(Icons.difference, size: 16),
              label: const Text('Compare'),
            ),
        ],
      ),
    );
  }

  static Color _statusColor(ResponseModel response) {
    if (response.isSuccess) return Colors.green;
    if (response.statusCode >= 300 && response.statusCode < 400) {
      return Colors.orange;
    }
    return Colors.redAccent;
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _ResponseMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ResponseMetricChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
          const SizedBox(width: AppTokens.s1),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseBodyTab extends StatefulWidget {
  final ResponseModel response;

  const _ResponseBodyTab({required this.response});

  @override
  State<_ResponseBodyTab> createState() => _ResponseBodyTabState();
}

class _ResponseBodyTabState extends State<_ResponseBodyTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyText = _bodyAsText(widget.response);
    final matchCount = _countMatches(bodyText, _query);

    if (bodyText.isEmpty) {
      return const _EmptyInlineState(
        icon: Icons.short_text_outlined,
        title: 'Empty body',
        message: 'The response completed without a response payload.',
      );
    }

    return Column(
      children: [
        _BodyToolBar(
          controller: _searchController,
          matchCount: matchCount,
          onChanged: (value) => setState(() => _query = value),
          onClear: () {
            _searchController.clear();
            setState(() => _query = '');
          },
          onCopy: () => _copyToClipboard(context, bodyText, 'Response body'),
        ),
        Expanded(
          child: _query.trim().isNotEmpty
              ? _SearchableBodyView(body: bodyText, query: _query)
              : widget.response.jsonBody != null
                  ? _JsonBodyView(jsonBody: widget.response.jsonBody)
                  : _SearchableBodyView(body: bodyText, query: _query),
        ),
      ],
    );
  }

  String _bodyAsText(ResponseModel response) {
    if (response.jsonBody == null) return response.body;

    try {
      return const JsonEncoder.withIndent('  ').convert(response.jsonBody);
    } catch (_) {
      return response.body;
    }
  }
}

class _JsonBodyView extends StatelessWidget {
  final dynamic jsonBody;

  const _JsonBodyView({required this.jsonBody});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: _codeBackground(context),
      padding: const EdgeInsets.all(AppTokens.s4),
      child: JsonView.map(
        _jsonAsMap(jsonBody),
        theme: JsonViewTheme(
          backgroundColor: Colors.transparent,
          keyStyle: AppTokens.monoStyle.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          stringStyle: AppTokens.monoStyle.copyWith(color: Colors.green),
          intStyle: AppTokens.monoStyle.copyWith(color: Colors.orange),
          doubleStyle: AppTokens.monoStyle.copyWith(color: Colors.orange),
          boolStyle: AppTokens.monoStyle.copyWith(color: Colors.purpleAccent),
          defaultTextStyle: AppTokens.monoStyle.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _jsonAsMap(dynamic jsonBody) {
    if (jsonBody is Map<String, dynamic>) return jsonBody;
    if (jsonBody is Map) {
      return jsonBody.map((key, value) => MapEntry(key.toString(), value));
    }
    return {'data': jsonBody};
  }
}

class _BodyToolBar extends StatelessWidget {
  final TextEditingController controller;
  final int matchCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onCopy;

  const _BodyToolBar({
    required this.controller,
    required this.matchCount,
    required this.onChanged,
    required this.onClear,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppTokens.s2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final searchField = TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search body',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: hasQuery
                  ? IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: onClear,
                    )
                  : null,
              isDense: true,
            ),
          );
          final metric = _TinyMetric(
            icon: Icons.manage_search,
            label: hasQuery ? '$matchCount matches' : 'Search ready',
          );
          final copyButton = TextButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_all_outlined, size: 16),
            label: const Text('Copy body'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: AppTokens.s2),
                Row(
                  children: [
                    metric,
                    const Spacer(),
                    copyButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 260, child: searchField),
              const SizedBox(width: AppTokens.s2),
              metric,
              const Spacer(),
              copyButton,
            ],
          );
        },
      ),
    );
  }
}

class _SearchableBodyView extends StatelessWidget {
  final String body;
  final String query;

  const _SearchableBodyView({
    required this.body,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: _codeBackground(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.s4),
        child: SelectableText.rich(
          TextSpan(
            children: _highlightMatches(
              body,
              query,
              AppTokens.monoStyle.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponseHeadersTab extends StatefulWidget {
  final ResponseModel response;

  const _ResponseHeadersTab({required this.response});

  @override
  State<_ResponseHeadersTab> createState() => _ResponseHeadersTabState();
}

class _ResponseHeadersTabState extends State<_ResponseHeadersTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.response.headers.isEmpty) {
      return const _EmptyInlineState(
        icon: Icons.notes_outlined,
        title: 'No headers',
        message: 'This response did not include headers.',
      );
    }

    final entries = widget.response.headers.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    final filteredEntries = _filterHeaders(entries, _query);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedRows = constraints.maxWidth < 560;

        return Column(
          children: [
            _HeadersToolBar(
              controller: _searchController,
              visibleCount: filteredEntries.length,
              totalCount: entries.length,
              onChanged: (value) => setState(() => _query = value),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              onCopyAll: () => _copyToClipboard(
                context,
                _headersAsText(entries),
                'Response headers',
              ),
            ),
            Expanded(
              child: filteredEntries.isEmpty
                  ? const _EmptyInlineState(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'No matching headers',
                      message: 'Try a different header name or value.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppTokens.s3),
                      itemCount: filteredEntries.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTokens.s2),
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        final value = entry.value.join(', ');

                        return _HeaderRow(
                          name: entry.key,
                          value: value,
                          stacked: useStackedRows,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  List<MapEntry<String, List<String>>> _filterHeaders(
    List<MapEntry<String, List<String>>> entries,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return entries;

    return entries.where((entry) {
      final value = entry.value.join(', ');
      return entry.key.toLowerCase().contains(normalized) ||
          value.toLowerCase().contains(normalized);
    }).toList();
  }

  String _headersAsText(List<MapEntry<String, List<String>>> entries) {
    return entries
        .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
        .join('\n');
  }
}

class _HeadersToolBar extends StatelessWidget {
  final TextEditingController controller;
  final int visibleCount;
  final int totalCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onCopyAll;

  const _HeadersToolBar({
    required this.controller,
    required this.visibleCount,
    required this.totalCount,
    required this.onChanged,
    required this.onClear,
    required this.onCopyAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppTokens.s2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final searchField = TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Filter headers',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: hasQuery
                  ? IconButton(
                      tooltip: 'Clear filter',
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: onClear,
                    )
                  : null,
              isDense: true,
            ),
          );
          final metric = _TinyMetric(
            icon: Icons.notes_outlined,
            label:
                hasQuery ? '$visibleCount of $totalCount' : '$totalCount total',
          );
          final copyButton = TextButton.icon(
            onPressed: onCopyAll,
            icon: const Icon(Icons.copy_all_outlined, size: 16),
            label: const Text('Copy all'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: AppTokens.s2),
                Row(
                  children: [
                    metric,
                    const Spacer(),
                    copyButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 260, child: searchField),
              const SizedBox(width: AppTokens.s2),
              metric,
              const Spacer(),
              copyButton,
            ],
          );
        },
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String name;
  final String value;
  final bool stacked;

  const _HeaderRow({
    required this.name,
    required this.value,
    required this.stacked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final nameWidget = SelectableText(
      name,
      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
    final valueWidget = SelectableText(
      value,
      style: AppTokens.monoStyle.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
        fontSize: 12,
      ),
    );

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
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: nameWidget),
                    IconButton(
                      tooltip: 'Copy header',
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      onPressed: () => _copyToClipboard(
                        context,
                        '$name: $value',
                        'Header',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s1),
                valueWidget,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 180, child: nameWidget),
                const SizedBox(width: AppTokens.s3),
                Expanded(child: valueWidget),
                IconButton(
                  tooltip: 'Copy header',
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  onPressed: () => _copyToClipboard(
                    context,
                    '$name: $value',
                    'Header',
                  ),
                ),
              ],
            ),
    );
  }
}

class _TinyMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TinyMetric({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
          ),
          const SizedBox(width: AppTokens.s1),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.70),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResponseState extends StatelessWidget {
  const _EmptyResponseState();

  @override
  Widget build(BuildContext context) {
    return const _EmptyInlineState(
      icon: Icons.bolt_outlined,
      title: 'No response yet',
      message: 'Send a request to inspect status, headers, and body here.',
    );
  }
}

class _ResponseLoadingState extends StatelessWidget {
  const _ResponseLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppTokens.s3),
          Text(
            'Sending request...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseErrorState extends StatelessWidget {
  final Object error;

  const _ResponseErrorState({required this.error});

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
                'Error: $error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInlineState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyInlineState({
    required this.icon,
    required this.title,
    required this.message,
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
            Icon(
              icon,
              size: 34,
              color: theme.colorScheme.primary.withValues(alpha: 0.65),
            ),
            const SizedBox(height: AppTokens.s3),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
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

Color _codeBackground(BuildContext context) {
  final theme = Theme.of(context);
  final tint = theme.brightness == Brightness.dark
      ? Colors.black.withValues(alpha: 0.16)
      : Colors.white.withValues(alpha: 0.55);

  return Color.alphaBlend(tint, theme.scaffoldBackgroundColor);
}

int _countMatches(String source, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (source.isEmpty || normalizedQuery.isEmpty) return 0;

  var count = 0;
  var start = 0;
  final normalizedSource = source.toLowerCase();
  while (true) {
    final index = normalizedSource.indexOf(normalizedQuery, start);
    if (index == -1) break;
    count++;
    start = index + normalizedQuery.length;
  }
  return count;
}

List<TextSpan> _highlightMatches(
  String source,
  String query,
  TextStyle baseStyle,
  Color highlightColor,
) {
  final normalizedQuery = query.trim().toLowerCase();
  if (source.isEmpty || normalizedQuery.isEmpty) {
    return [TextSpan(text: source, style: baseStyle)];
  }

  final spans = <TextSpan>[];
  final normalizedSource = source.toLowerCase();
  var start = 0;

  while (true) {
    final index = normalizedSource.indexOf(normalizedQuery, start);
    if (index == -1) {
      spans.add(TextSpan(text: source.substring(start), style: baseStyle));
      break;
    }

    if (index > start) {
      spans.add(
          TextSpan(text: source.substring(start, index), style: baseStyle));
    }

    final end = index + normalizedQuery.length;
    spans.add(
      TextSpan(
        text: source.substring(index, end),
        style: baseStyle.copyWith(
          color: highlightColor,
          backgroundColor: highlightColor.withValues(alpha: 0.18),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    start = end;
  }

  return spans;
}

Future<void> _copyToClipboard(
  BuildContext context,
  String value,
  String label,
) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label copied to clipboard')),
  );
}
