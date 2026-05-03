import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../../../execution/application/workflow_runner_controller.dart';

class DebugPanel extends ConsumerWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runner = ref.watch(workflowRunnerProvider);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _DebugHeader(
            logCount: runner.logs.length,
            resultCount: runner.results.length,
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          const Expanded(
            child: TabBarView(
              children: [
                _LogView(),
                _ContextView(),
                Center(child: Text('Variables not supported yet')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugHeader extends StatelessWidget {
  final int logCount;
  final int resultCount;

  const _DebugHeader({
    required this.logCount,
    required this.resultCount,
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
          Icon(Icons.bug_report_outlined,
              size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.s2),
          Expanded(
            child: Text(
              'Debug',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 340,
            child: TabBar(
              tabs: [
                Tab(text: 'Run Logs ($logCount)'),
                Tab(text: 'Node Output ($resultCount)'),
                const Tab(text: 'Variables'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogView extends ConsumerStatefulWidget {
  const _LogView();

  @override
  ConsumerState<_LogView> createState() => _LogViewState();
}

class _LogViewState extends ConsumerState<_LogView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(workflowRunnerProvider).logs;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    if (logs.isEmpty) {
      return const _DebugEmptyState(
        icon: Icons.terminal_outlined,
        title: 'No logs yet',
        message: 'Run a workflow to stream execution logs here.',
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTokens.s3),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s1),
      itemBuilder: (context, index) {
        return _LogLine(text: logs[index]);
      },
    );
  }
}

class _LogLine extends StatelessWidget {
  final String text;

  const _LogLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.025),
          theme.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s2,
          vertical: AppTokens.s1,
        ),
        child: SelectableText(
          text,
          style: AppTokens.monoStyle.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ContextView extends ConsumerWidget {
  const _ContextView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(workflowRunnerProvider).results;

    if (results.isEmpty) {
      return const _DebugEmptyState(
        icon: Icons.dataset_outlined,
        title: 'No context data',
        message:
            'Node outputs and runtime context will appear after execution.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTokens.s3),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s2),
      itemBuilder: (context, index) {
        final nodeId = results.keys.elementAt(index);
        final result = results[nodeId]!;
        final dataPreview = _formatResultData(result.responseBody);

        return _ResultCard(
          nodeId: nodeId,
          status: result.status.name,
          durationMs: result.finishedAt
                  ?.difference(result.startedAt ?? result.finishedAt!)
                  .inMilliseconds ??
              0,
          error: result.errorMessage,
          dataPreview: dataPreview,
        );
      },
    );
  }

  String _formatResultData(dynamic responseBody) {
    if (responseBody == null) return '';

    try {
      return const JsonEncoder.withIndent('  ').convert(responseBody);
    } catch (_) {
      return responseBody.toString();
    }
  }
}

class _ResultCard extends StatelessWidget {
  final String nodeId;
  final String status;
  final int durationMs;
  final String? error;
  final String dataPreview;

  const _ResultCard({
    required this.nodeId,
    required this.status,
    required this.durationMs,
    required this.dataPreview,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(status);

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppTokens.s3),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppTokens.s3,
        0,
        AppTokens.s3,
        AppTokens.s3,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        side: BorderSide(color: theme.dividerColor),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        side: BorderSide(color: theme.dividerColor),
      ),
      leading: Icon(Icons.circle, size: 10, color: color),
      title: Text(
        nodeId,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('$status / ${durationMs}ms'),
      children: [
        if (error != null)
          _ResultBlock(
            title: 'Error',
            text: error!,
            color: theme.colorScheme.error,
          ),
        if (dataPreview.isNotEmpty)
          _ResultBlock(
            title: 'Data',
            text: dataPreview,
            color: theme.colorScheme.primary,
          ),
      ],
    );
  }
}

class _ResultBlock extends StatelessWidget {
  final String title;
  final String text;
  final Color color;

  const _ResultBlock({
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppTokens.s2),
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.20)),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTokens.s1),
          SelectableText(
            text,
            style: AppTokens.monoStyle.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _DebugEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 32,
            color: theme.colorScheme.primary.withValues(alpha: 0.62),
          ),
          const SizedBox(height: AppTokens.s2),
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
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'success':
      return Colors.green;
    case 'failure':
      return Colors.redAccent;
    default:
      return Colors.orange;
  }
}
