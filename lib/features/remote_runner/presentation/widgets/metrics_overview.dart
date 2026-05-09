import 'package:flutter/material.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../../domain/models/metrics_models.dart';

class MetricsOverview extends StatelessWidget {
  final RunMetricsSnapshot metrics;

  const MetricsOverview({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final errorRate = (metrics.errorRate * 100).toStringAsFixed(2);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 720 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: AppTokens.s3,
          mainAxisSpacing: AppTokens.s3,
          childAspectRatio: constraints.maxWidth > 720 ? 1.8 : 1.35,
          children: [
            _MetricTile(label: 'Requests', value: '${metrics.requestCount}'),
            _MetricTile(label: 'Errors', value: '${metrics.errorCount}'),
            _MetricTile(label: 'Error Rate', value: '$errorRate%'),
            _MetricTile(label: 'Updated', value: _time(metrics.updatedAt)),
          ],
        );
      },
    );
  }

  String _time(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.s3),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: AppTokens.s1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
