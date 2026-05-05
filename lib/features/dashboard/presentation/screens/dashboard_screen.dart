import 'package:flutter/material.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import '../widgets/stat_card.dart';
import '../widgets/traffic_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppTokens.s6),
            _buildStatGrid(context),
            const SizedBox(height: AppTokens.s6),
            const SizedBox(
              height: 400,
              child: TrafficChart(),
            ),
            const SizedBox(height: AppTokens.s6),
            _buildRecentPerformance(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API Dashboard Summary - Global Payments',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time overview of your API orchestration health and performance.',
          style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF958EA0)),
        ),
      ],
    );
  }

  Widget _buildStatGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppTokens.s4,
          mainAxisSpacing: AppTokens.s4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: constraints.maxWidth > 800 ? 1.6 : 1.2,
          children: const [
            StatCard(
              title: 'API HEALTH',
              value: '98.4%',
              trend: '12%',
              isPositive: true,
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
            StatCard(
              title: 'AVG. RESPONSE TIME',
              value: '142 ms',
              trend: '5ms',
              isPositive: true,
              icon: Icons.speed,
              color: Color(0xFF8B5CF6),
            ),
            StatCard(
              title: 'TOTAL REQUESTS',
              value: '3.5M',
              trend: '12%',
              isPositive: true,
              icon: Icons.swap_horiz,
              color: Color(0xFF06B6D4),
            ),
            StatCard(
              title: 'ERROR RATE',
              value: '0.35%',
              trend: 'stable',
              isPositive: true,
              icon: Icons.error_outline,
              color: Color(0xFFFFB4AB),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentPerformance(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT API PERFORMANCE',
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 1.2,
            color: isDark ? const Color(0xFF958EA0) : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                children: [
                  Expanded(child: _buildPerformanceItem(context, 'Checkout API', '112ms', '99.1%', Colors.green)),
                  const SizedBox(width: AppTokens.s4),
                  Expanded(child: _buildPerformanceItem(context, 'Payment-Init', '155ms', '97.9%', Colors.orange)),
                  const SizedBox(width: AppTokens.s4),
                  Expanded(child: _buildPerformanceItem(context, 'User-Auth', '98ms', '99.8%', Colors.green)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildPerformanceItem(context, 'Checkout API', '112ms', '99.1%', Colors.green),
                  const SizedBox(height: AppTokens.s4),
                  _buildPerformanceItem(context, 'Payment-Init', '155ms', '97.9%', Colors.orange),
                  const SizedBox(height: AppTokens.s4),
                  _buildPerformanceItem(context, 'User-Auth', '98ms', '99.8%', Colors.green),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPerformanceItem(
    BuildContext context,
    String name,
    String latency,
    String success,
    Color statusColor,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
        padding: const EdgeInsets.all(AppTokens.s4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171F33) : Colors.white,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isDark ? const Color(0xFF2D3449) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                Text(latency, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusColor == Colors.green ? 'Healthy' : 'Warning',
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  success,
                  style: theme.textTheme.bodySmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      );
  }
}
