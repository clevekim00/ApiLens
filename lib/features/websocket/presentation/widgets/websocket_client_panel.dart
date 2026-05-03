import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../../application/websocket_controller.dart';
import '../../data/websocket_config_repository.dart';
import '../../domain/models/websocket_message.dart';

class WebSocketClientPanel extends ConsumerStatefulWidget {
  final bool showHeader;

  const WebSocketClientPanel({
    super.key,
    this.showHeader = true,
  });

  @override
  ConsumerState<WebSocketClientPanel> createState() =>
      _WebSocketClientPanelState();
}

class _WebSocketClientPanelState extends ConsumerState<WebSocketClientPanel> {
  static const double _sideBySideBreakpoint = 940;

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _logFilterController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();
  bool _prettyPrintJson = false;
  _MessageLogFilter _logFilter = _MessageLogFilter.all;
  String _logQuery = '';
  final Set<String> _pinnedMessageIds = {};
  bool _showPinnedOnly = false;

  @override
  void dispose() {
    _urlController.dispose();
    _messageController.dispose();
    _logFilterController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(webSocketClientProvider);
    final session = state.session;

    ref.listen(webSocketClientProvider, (prev, next) {
      if (prev?.selectedConfigId != next.selectedConfigId &&
          next.selectedConfigId != null) {
        _loadConfigUrl(next.selectedConfigId!);
      }
    });

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
                if (widget.showHeader) ...[
                  _ConnectionBar(
                    urlController: _urlController,
                    session: session,
                    onConnect: _handleConnect,
                    onDisconnect: () =>
                        ref.read(webSocketClientProvider.notifier).disconnect(),
                  ),
                  const SizedBox(height: AppTokens.s3),
                ],
                Expanded(
                  child: useSideBySide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _LogPanel(
                                session: session,
                                controller: _logScrollController,
                                searchController: _logFilterController,
                                query: _logQuery,
                                filter: _logFilter,
                                pinnedMessageIds: _pinnedMessageIds,
                                showPinnedOnly: _showPinnedOnly,
                                onQueryChanged: (value) {
                                  setState(() => _logQuery = value);
                                },
                                onQueryClear: () {
                                  _logFilterController.clear();
                                  setState(() => _logQuery = '');
                                },
                                onFilterChanged: (value) {
                                  setState(() => _logFilter = value);
                                },
                                onPinnedOnlyChanged: (value) {
                                  setState(() => _showPinnedOnly = value);
                                },
                                onTogglePin: _togglePinnedMessage,
                                onClear: () => ref
                                    .read(webSocketClientProvider.notifier)
                                    .clearLog(),
                              ),
                            ),
                            const SizedBox(width: AppTokens.s3),
                            SizedBox(
                              width: 360,
                              child: _ComposerPanel(
                                controller: _messageController,
                                connected: session.status ==
                                    WebSocketConnectionStatus.connected,
                                prettyPrintJson: _prettyPrintJson,
                                onPrettyPrintChanged: (value) {
                                  setState(() => _prettyPrintJson = value);
                                },
                                onSend: _handleSend,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: _LogPanel(
                                session: session,
                                controller: _logScrollController,
                                searchController: _logFilterController,
                                query: _logQuery,
                                filter: _logFilter,
                                pinnedMessageIds: _pinnedMessageIds,
                                showPinnedOnly: _showPinnedOnly,
                                onQueryChanged: (value) {
                                  setState(() => _logQuery = value);
                                },
                                onQueryClear: () {
                                  _logFilterController.clear();
                                  setState(() => _logQuery = '');
                                },
                                onFilterChanged: (value) {
                                  setState(() => _logFilter = value);
                                },
                                onPinnedOnlyChanged: (value) {
                                  setState(() => _showPinnedOnly = value);
                                },
                                onTogglePin: _togglePinnedMessage,
                                onClear: () => ref
                                    .read(webSocketClientProvider.notifier)
                                    .clearLog(),
                              ),
                            ),
                            const SizedBox(height: AppTokens.s3),
                            SizedBox(
                              height: 190,
                              child: _ComposerPanel(
                                controller: _messageController,
                                connected: session.status ==
                                    WebSocketConnectionStatus.connected,
                                prettyPrintJson: _prettyPrintJson,
                                onPrettyPrintChanged: (value) {
                                  setState(() => _prettyPrintJson = value);
                                },
                                onSend: _handleSend,
                              ),
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

  void _togglePinnedMessage(String id) {
    setState(() {
      if (_pinnedMessageIds.contains(id)) {
        _pinnedMessageIds.remove(id);
      } else {
        _pinnedMessageIds.add(id);
      }
    });
  }

  Future<void> _loadConfigUrl(String id) async {
    final config = await ref.read(webSocketConfigRepositoryProvider).get(id);
    if (config != null && mounted) {
      _urlController.text = config.url;
    }
  }

  Future<void> _handleConnect() async {
    final controller = ref.read(webSocketClientProvider.notifier);
    final state = ref.read(webSocketClientProvider);

    if (_urlController.text.trim().isEmpty) return;

    if (state.selectedConfigId == null) {
      final newConfig =
          await ref.read(webSocketConfigRepositoryProvider).saveNew(
                name: 'Untitled',
                url: _urlController.text.trim(),
              );
      await controller.selectConfig(newConfig.id);
    }

    await controller.connect();
  }

  void _handleSend() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    if (_prettyPrintJson) {
      try {
        final formatted =
            const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
        _messageController.text = formatted;
      } catch (_) {
        // Keep the original payload when it is not valid JSON.
      }
    }

    ref
        .read(webSocketClientProvider.notifier)
        .sendMessage(_messageController.text);
  }
}

class _ConnectionBar extends StatelessWidget {
  final TextEditingController urlController;
  final WebSocketSessionState session;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _ConnectionBar({
    required this.urlController,
    required this.session,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final status = session.status;
    final isConnected = status == WebSocketConnectionStatus.connected;
    final isConnecting = status == WebSocketConnectionStatus.connecting;

    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final urlField = TextField(
              key: const Key('input_ws_url'),
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'ws://example.com/socket',
                prefixIcon: Icon(Icons.link, size: 18),
                isDense: true,
              ),
            );
            final actionButton = FilledButton.icon(
              key: isConnected || isConnecting
                  ? null
                  : const Key('btn_ws_connect'),
              onPressed: isConnecting
                  ? null
                  : isConnected
                      ? onDisconnect
                      : onConnect,
              icon: Icon(isConnected ? Icons.link_off : Icons.link),
              label: Text(isConnected
                  ? 'Disconnect'
                  : isConnecting
                      ? 'Connecting...'
                      : 'Connect'),
              style: FilledButton.styleFrom(
                backgroundColor: isConnected ? Colors.redAccent : Colors.green,
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _StatusPill(status: status),
                      const SizedBox(width: AppTokens.s2),
                      Expanded(child: Text(_statusHelp(session))),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s2),
                  urlField,
                  const SizedBox(height: AppTokens.s2),
                  actionButton,
                ],
              );
            }

            return Row(
              children: [
                _StatusPill(status: status),
                const SizedBox(width: AppTokens.s2),
                Expanded(child: urlField),
                const SizedBox(width: AppTokens.s2),
                actionButton,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LogPanel extends StatelessWidget {
  final WebSocketSessionState session;
  final ScrollController controller;
  final TextEditingController searchController;
  final String query;
  final _MessageLogFilter filter;
  final Set<String> pinnedMessageIds;
  final bool showPinnedOnly;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onQueryClear;
  final ValueChanged<_MessageLogFilter> onFilterChanged;
  final ValueChanged<bool> onPinnedOnlyChanged;
  final ValueChanged<String> onTogglePin;
  final VoidCallback onClear;

  const _LogPanel({
    required this.session,
    required this.controller,
    required this.searchController,
    required this.query,
    required this.filter,
    required this.pinnedMessageIds,
    required this.showPinnedOnly,
    required this.onQueryChanged,
    required this.onQueryClear,
    required this.onFilterChanged,
    required this.onPinnedOnlyChanged,
    required this.onTogglePin,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredMessages = _filterMessages(
      session.messages,
      filter,
      query,
      pinnedMessageIds: pinnedMessageIds,
      showPinnedOnly: showPinnedOnly,
    );
    final pinnedCount =
        session.messages.where((m) => pinnedMessageIds.contains(m.id)).length;

    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: Column(
        children: [
          _PanelHeader(
            icon: Icons.receipt_long_outlined,
            title: 'Message Log',
            subtitle:
                '${session.messages.length} messages / $pinnedCount pinned',
            trailing: Wrap(
              spacing: AppTokens.s1,
              children: [
                TextButton.icon(
                  onPressed: filteredMessages.isEmpty
                      ? null
                      : () => _exportMessages(context, filteredMessages),
                  icon: const Icon(Icons.ios_share_outlined, size: 16),
                  label: const Text('Export'),
                ),
                TextButton.icon(
                  onPressed: session.messages.isEmpty ? null : onClear,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          _LogTools(
            controller: searchController,
            query: query,
            filter: filter,
            pinnedCount: pinnedCount,
            showPinnedOnly: showPinnedOnly,
            visibleCount: filteredMessages.length,
            totalCount: session.messages.length,
            onChanged: onQueryChanged,
            onClear: onQueryClear,
            onFilterChanged: onFilterChanged,
            onPinnedOnlyChanged: onPinnedOnlyChanged,
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: session.messages.isEmpty
                ? const _WebSocketEmptyState()
                : filteredMessages.isEmpty
                    ? const _WebSocketEmptyState(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'No matching messages',
                        message: 'Try a different search term or direction.',
                      )
                    : ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.all(AppTokens.s3),
                        itemCount: filteredMessages.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppTokens.s2),
                        itemBuilder: (context, index) {
                          final message = filteredMessages[index];
                          return _MessageCard(
                            message: message,
                            pinned: pinnedMessageIds.contains(message.id),
                            onTogglePin: () => onTogglePin(message.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _LogTools extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final _MessageLogFilter filter;
  final int pinnedCount;
  final bool showPinnedOnly;
  final int visibleCount;
  final int totalCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<_MessageLogFilter> onFilterChanged;
  final ValueChanged<bool> onPinnedOnlyChanged;

  const _LogTools({
    required this.controller,
    required this.query,
    required this.filter,
    required this.pinnedCount,
    required this.showPinnedOnly,
    required this.visibleCount,
    required this.totalCount,
    required this.onChanged,
    required this.onClear,
    required this.onFilterChanged,
    required this.onPinnedOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = query.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(AppTokens.s2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final searchField = SizedBox(
            width: compact ? double.infinity : 260,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search payload',
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
            ),
          );

          final filterChips = Wrap(
            spacing: AppTokens.s1,
            runSpacing: AppTokens.s1,
            children: [
              ..._MessageLogFilter.values.map((value) {
                return ChoiceChip(
                  label: Text(value.label),
                  selected: filter == value,
                  onSelected: (_) => onFilterChanged(value),
                );
              }),
              FilterChip(
                avatar: const Icon(Icons.push_pin_outlined, size: 14),
                label: Text('Pinned $pinnedCount'),
                selected: showPinnedOnly,
                onSelected: pinnedCount == 0
                    ? null
                    : (value) => onPinnedOnlyChanged(value),
              ),
            ],
          );

          final count = Text(
            hasQuery || filter != _MessageLogFilter.all || showPinnedOnly
                ? '$visibleCount of $totalCount shown'
                : '$totalCount messages',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: AppTokens.s2),
                Row(
                  children: [
                    Expanded(child: filterChips),
                    const SizedBox(width: AppTokens.s2),
                    count,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              searchField,
              const SizedBox(width: AppTokens.s2),
              Expanded(child: filterChips),
              const SizedBox(width: AppTokens.s2),
              count,
            ],
          );
        },
      ),
    );
  }
}

class _ComposerPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool connected;
  final bool prettyPrintJson;
  final ValueChanged<bool> onPrettyPrintChanged;
  final VoidCallback onSend;

  const _ComposerPanel({
    required this.controller,
    required this.connected,
    required this.prettyPrintJson,
    required this.onPrettyPrintChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: Column(
        children: [
          _PanelHeader(
            icon: Icons.send_outlined,
            title: 'Composer',
            subtitle: connected ? 'Ready to send' : 'Connect first',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('JSON', style: theme.textTheme.labelMedium),
                Switch(
                  value: prettyPrintJson,
                  onChanged: onPrettyPrintChanged,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: AppTokens.monoStyle.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                hintText: 'Message payload...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.all(AppTokens.s3),
                filled: false,
              ),
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(AppTokens.s2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    connected
                        ? 'Ctrl/Cmd+Enter support can be added next.'
                        : 'Connection required.',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.58),
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: connected ? onSend : null,
                  icon: const Icon(Icons.send),
                  tooltip: 'Send message',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final WebSocketMessage message;
  final bool pinned;
  final VoidCallback onTogglePin;

  const _MessageCard({
    required this.message,
    required this.pinned,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _directionColor(message.direction);

    return Container(
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          (pinned ? Colors.amber : color)
              .withValues(alpha: pinned ? 0.075 : 0.045),
          theme.colorScheme.surface,
        ),
        border: Border.all(
          color: pinned
              ? Colors.amber.withValues(alpha: 0.46)
              : color.withValues(alpha: 0.22),
        ),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _DirectionBadge(direction: message.direction),
              const SizedBox(width: AppTokens.s2),
              Text(
                DateFormat('HH:mm:ss.SSS').format(message.timestamp),
                style: theme.textTheme.labelMedium,
              ),
              const Spacer(),
              IconButton(
                tooltip: pinned ? 'Unpin message' : 'Pin message',
                icon: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 16,
                  color: pinned ? Colors.amber.shade700 : null,
                ),
                onPressed: onTogglePin,
              ),
              IconButton(
                tooltip: 'Copy payload',
                icon: const Icon(Icons.copy_outlined, size: 16),
                onPressed: () => _copyToClipboard(
                  context,
                  message.payloadText,
                  'Payload',
                ),
              ),
              Text(
                '${message.sizeBytes} bytes',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                ),
              ),
              if (message.parsedJson != null) ...[
                const SizedBox(width: AppTokens.s2),
                Icon(Icons.data_object, size: 16, color: color),
              ],
            ],
          ),
          const SizedBox(height: AppTokens.s2),
          SelectableText(
            message.payloadText,
            maxLines: 12,
            style: AppTokens.monoStyle.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _StatusPill extends StatelessWidget {
  final WebSocketConnectionStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: AppTokens.s2),
          Text(
            status.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _DirectionBadge extends StatelessWidget {
  final WebSocketMessageDirection direction;

  const _DirectionBadge({required this.direction});

  @override
  Widget build(BuildContext context) {
    final color = _directionColor(direction);

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_directionIcon(direction), size: 13, color: color),
          const SizedBox(width: AppTokens.s1),
          Text(
            direction.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _WebSocketEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _WebSocketEmptyState({
    this.icon = Icons.forum_outlined,
    this.title = 'No messages yet',
    this.message =
        'Connect to a socket and sent/received messages will appear here.',
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

String _statusHelp(WebSocketSessionState session) {
  if (session.lastError != null && session.lastError!.isNotEmpty) {
    return session.lastError!;
  }
  switch (session.status) {
    case WebSocketConnectionStatus.disconnected:
      return 'Enter a socket URL to start.';
    case WebSocketConnectionStatus.connecting:
      return 'Opening connection...';
    case WebSocketConnectionStatus.connected:
      return 'Connection is active.';
    case WebSocketConnectionStatus.error:
      return 'Connection error.';
  }
}

Color _statusColor(WebSocketConnectionStatus status) {
  switch (status) {
    case WebSocketConnectionStatus.connected:
      return Colors.green;
    case WebSocketConnectionStatus.connecting:
      return Colors.orange;
    case WebSocketConnectionStatus.error:
      return Colors.redAccent;
    case WebSocketConnectionStatus.disconnected:
      return Colors.blueGrey;
  }
}

IconData _directionIcon(WebSocketMessageDirection direction) {
  switch (direction) {
    case WebSocketMessageDirection.sent:
      return Icons.arrow_upward;
    case WebSocketMessageDirection.received:
      return Icons.arrow_downward;
    case WebSocketMessageDirection.system:
      return Icons.info_outline;
  }
}

Color _directionColor(WebSocketMessageDirection direction) {
  switch (direction) {
    case WebSocketMessageDirection.sent:
      return Colors.blue;
    case WebSocketMessageDirection.received:
      return Colors.green;
    case WebSocketMessageDirection.system:
      return Colors.blueGrey;
  }
}

enum _MessageLogFilter {
  all('All'),
  sent('Sent'),
  received('Received'),
  system('System');

  final String label;

  const _MessageLogFilter(this.label);
}

List<WebSocketMessage> _filterMessages(
  List<WebSocketMessage> messages,
  _MessageLogFilter filter,
  String query, {
  required Set<String> pinnedMessageIds,
  required bool showPinnedOnly,
}) {
  final normalizedQuery = query.trim().toLowerCase();

  return messages.where((message) {
    if (showPinnedOnly && !pinnedMessageIds.contains(message.id)) {
      return false;
    }

    final directionMatches = switch (filter) {
      _MessageLogFilter.all => true,
      _MessageLogFilter.sent =>
        message.direction == WebSocketMessageDirection.sent,
      _MessageLogFilter.received =>
        message.direction == WebSocketMessageDirection.received,
      _MessageLogFilter.system =>
        message.direction == WebSocketMessageDirection.system,
    };

    if (!directionMatches) return false;
    if (normalizedQuery.isEmpty) return true;

    return message.payloadText.toLowerCase().contains(normalizedQuery) ||
        DateFormat('HH:mm:ss.SSS')
            .format(message.timestamp)
            .toLowerCase()
            .contains(normalizedQuery);
  }).toList();
}

Future<void> _exportMessages(
  BuildContext context,
  List<WebSocketMessage> messages,
) async {
  final jsonText = const JsonEncoder.withIndent('  ').convert(
    messages.map((message) => message.toJson()).toList(),
  );
  await Clipboard.setData(ClipboardData(text: jsonText));
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text('${messages.length} messages exported to clipboard')),
  );
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
