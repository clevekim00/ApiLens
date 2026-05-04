import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../history/providers/history_provider.dart';
import '../../history/models/history_item.dart';
import '../../request/providers/request_provider.dart';
import '../../request/models/key_value_item.dart';
import '../../request/models/request_model.dart'; // for AuthType enum mapping
import '../../workgroup/presentation/widgets/workgroup_explorer.dart';
import '../../../core/ui/tokens/app_tokens.dart';

class HistoryPanel extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  final bool showCloseButton;

  const HistoryPanel({
    super.key,
    this.onClose,
    this.showCloseButton = true,
  });

  @override
  ConsumerState<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends ConsumerState<HistoryPanel> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyNotifierProvider);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.canvasColor,
      ),
      child: _buildHistoryTab(historyAsync, theme),
    );
  }

  Widget _buildHistoryTab(
    AsyncValue<List<HistoryItem>> historyAsync,
    ThemeData theme,
  ) {
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s3,
            AppTokens.s3,
            AppTokens.s3,
            AppTokens.s2,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search URL or method',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: hasQuery
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        ref.read(historyNotifierProvider.notifier).search('');
                      },
                    )
                  : null,
              isDense: true,
            ),
            onChanged: (val) {
              ref.read(historyNotifierProvider.notifier).search(val);
            },
          ),
        ),
        Expanded(
          child: historyAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return _SidebarEmptyState(
                  icon: hasQuery
                      ? Icons.manage_search_outlined
                      : Icons.history_toggle_off_outlined,
                  title: hasQuery ? 'No matches' : 'No history yet',
                  message: hasQuery
                      ? 'Try a different URL or method keyword.'
                      : 'Sent requests will appear here for quick restore.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s2,
                  0,
                  AppTokens.s2,
                  AppTokens.s3,
                ),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTokens.s2),
                itemBuilder: (context, index) {
                  return _buildHistoryCard(items[index], theme);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _SidebarEmptyState(
              icon: Icons.error_outline,
              title: 'History unavailable',
              message: '$err',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(HistoryItem item, ThemeData theme) {
    final statusColor = _getStatusColor(item.statusCode);
    final methodColor = _getMethodColor(item.method);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        onTap: () => _restoreHistory(item),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.s2),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              theme.colorScheme.primary.withValues(alpha: 0.025),
              theme.colorScheme.surface,
            ),
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _TinyChip(
                    label: item.method,
                    color: methodColor,
                  ),
                  const SizedBox(width: AppTokens.s2),
                  Expanded(
                    child: Text(
                      item.url.isEmpty ? 'No URL' : item.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 17),
                    tooltip: 'Delete history item',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      ref
                          .read(historyNotifierProvider.notifier)
                          .deleteHistory(item.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s1),
              Row(
                children: [
                  _TinyChip(
                    label: '${item.statusCode}',
                    color: statusColor,
                    muted: true,
                  ),
                  const SizedBox(width: AppTokens.s2),
                  Icon(
                    Icons.timer_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: AppTokens.s1),
                  Text(
                    '${item.durationMs} ms',
                    style: theme.textTheme.labelMedium,
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MM/dd HH:mm').format(item.createdAt),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restoreHistory(HistoryItem item) {
    try {
      final headersList = (jsonDecode(item.headersJson) as List)
          .map((e) => KeyValueItem(
              id: const Uuid().v4(),
              key: e['key'],
              value: e['value'],
              isEnabled: e['isEnabled']))
          .toList();

      final paramsList = (jsonDecode(item.paramsJson) as List)
          .map((e) => KeyValueItem(
              id: const Uuid().v4(),
              key: e['key'],
              value: e['value'],
              isEnabled: e['isEnabled']))
          .toList();

      final authData = jsonDecode(item.authJson);
      final AuthType authType = AuthType.values.firstWhere(
          (e) => e.name == authData['type'],
          orElse: () => AuthType.none);

      final model = RequestModel(
        id: const Uuid().v4(), // temporary
        method: item.method,
        url: item.url,
        headers: headersList,
        params: paramsList,
        body: item.body,
        authType: authType,
        authData: Map<String, String>.from(authData['data']),
      );

      ref.read(requestNotifierProvider.notifier).restoreRequest(model);

      widget.onClose?.call(); // Close drawer mode after restore.
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request Restored')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to restore: $e')));
    }
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return Colors.green;
    if (statusCode >= 300 && statusCode < 400) return Colors.orange;
    if (statusCode >= 400) return Colors.redAccent;
    return Colors.grey;
  }
}

class _TinyChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool muted;

  const _TinyChip({
    required this.label,
    required this.color,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: muted ? 0.10 : 0.14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 2,
                ),
              ],
            ),
      ),
    );
  }
}

class _SidebarEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SidebarEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 30,
              color: theme.colorScheme.primary.withValues(alpha: 0.62),
            ),
            const SizedBox(height: AppTokens.s2),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14,
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
