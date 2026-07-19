import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/vega_background.dart';
import '../../widgets/glass_container.dart';
import '../../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _showDetailedMetrics = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('PERFORMANCE', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGraphToggle(),
              const SizedBox(height: 24),
              _buildChartCard(),
              const SizedBox(height: 24),
              if (_showDetailedMetrics)
                _buildDetailedMetrics().animate().fadeIn().slideY(begin: 0.1),
            ],
          ),
        ),
    );
  }

  Widget _buildGraphToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('ACS & K/D TRENDS', style: Theme.of(context).textTheme.labelLarge),
        Row(
          children: [
            Text('Detailed', style: Theme.of(context).textTheme.labelSmall),
            Switch(
              value: _showDetailedMetrics,
              onChanged: (val) {
                setState(() {
                  _showDetailedMetrics = val;
                });
              },
              activeColor: AppTheme.primaryContainer,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 50,
              getDrawingHorizontalLine: (value) {
                return const FlLine(color: Colors.white12, strokeWidth: 1);
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    const style = TextStyle(color: Colors.grey, fontSize: 10);
                    Widget text;
                    switch (value.toInt()) {
                      case 1: text = const Text('Week 1', style: style); break;
                      case 4: text = const Text('Week 2', style: style); break;
                      case 7: text = const Text('Week 3', style: style); break;
                      case 10: text = const Text('Week 4', style: style); break;
                      default: text = const Text('', style: style); break;
                    }
                    return SideTitleWidget(meta: meta, space: 4, child: text);
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 50,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                  },
                  reservedSize: 42,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: 11,
            minY: 0,
            maxY: 300,
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 150),
                  FlSpot(2.6, 180),
                  FlSpot(4.9, 160),
                  FlSpot(6.8, 220),
                  FlSpot(8, 200),
                  FlSpot(9.5, 250),
                  FlSpot(11, 240),
                ],
                isCurved: true,
                color: AppTheme.primaryContainer,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                ),
              ),
              LineChartBarData(
                spots: const [
                  FlSpot(0, 100),
                  FlSpot(2.6, 110),
                  FlSpot(4.9, 105),
                  FlSpot(6.8, 120),
                  FlSpot(8, 115),
                  FlSpot(9.5, 130),
                  FlSpot(11, 125),
                ],
                isCurved: true,
                color: Colors.tealAccent,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                dashArray: [5, 5],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildDetailedMetrics() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DETAILED BREAKDOWN', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 16),
          _buildMetricRow('Average Combat Score', '240', '+12%'),
          const Divider(color: Colors.white12),
          _buildMetricRow('Kill/Death Ratio', '1.25', '+0.15'),
          const Divider(color: Colors.white12),
          _buildMetricRow('Headshot Percentage', '22.4%', '-1.2%'),
          const Divider(color: Colors.white12),
          _buildMetricRow('First Bloods', '14', '+3'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, String change) {
    final isPositive = change.startsWith('+');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Row(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Text(change, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isPositive ? Colors.greenAccent : Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }
}
