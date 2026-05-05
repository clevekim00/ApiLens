import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/ui/tokens/app_tokens.dart';

class TrafficChart extends StatelessWidget {
  const TrafficChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTokens.s5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171F33) : Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3449) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 350;
              return isNarrow 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRAFFIC OVERVIEW (Last 24 Hours)',
                        style: theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.2,
                          color: isDark ? const Color(0xFF958EA0) : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: AppTokens.s2),
                      Row(
                        children: [
                          _buildLegendItem(context, 'Requests', const Color(0xFF4CD7F6)),
                          const SizedBox(width: AppTokens.s4),
                          _buildLegendItem(context, 'Errors', const Color(0xFFFFB4AB)),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'TRAFFIC OVERVIEW (Last 24 Hours)',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            letterSpacing: 1.2,
                            color: isDark ? const Color(0xFF958EA0) : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.s2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLegendItem(context, 'Requests', const Color(0xFF4CD7F6)),
                          const SizedBox(width: AppTokens.s4),
                          _buildLegendItem(context, 'Errors', const Color(0xFFFFB4AB)),
                        ],
                      ),
                    ],
                  );
            },
          ),
          const SizedBox(height: AppTokens.s6),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? const Color(0xFF2D3449) : Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Color(0xFF958EA0), fontSize: 10);
                        switch (value.toInt()) {
                          case 0: return const Text('00:00', style: style);
                          case 4: return const Text('04:00', style: style);
                          case 8: return const Text('08:00', style: style);
                          case 12: return const Text('12:00', style: style);
                          case 16: return const Text('16:00', style: style);
                          case 20: return const Text('20:00', style: style);
                          case 23: return const Text('00:00', style: style);
                        }
                        return const Text('', style: style);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 500,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toStringAsFixed(1)}K',
                          style: const TextStyle(color: Color(0xFF958EA0), fontSize: 10),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: 2000,
                lineBarsData: [
                  _buildLineChartBar(
                    [
                      const FlSpot(0, 400),
                      const FlSpot(4, 800),
                      const FlSpot(8, 700),
                      const FlSpot(12, 1200),
                      const FlSpot(16, 1100),
                      const FlSpot(20, 1600),
                      const FlSpot(23, 1300),
                    ],
                    const Color(0xFF4CD7F6),
                  ),
                  _buildLineChartBar(
                    [
                      const FlSpot(0, 50),
                      const FlSpot(4, 100),
                      const FlSpot(8, 80),
                      const FlSpot(12, 150),
                      const FlSpot(16, 120),
                      const FlSpot(20, 200),
                      const FlSpot(23, 180),
                    ],
                    const Color(0xFFFFB4AB),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineChartBar(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF958EA0)),
        ),
      ],
    );
  }
}
