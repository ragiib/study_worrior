// ============================================================================
// Study Stats Screen - Detailed graph of study hours
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';

class StudyStatsScreen extends StatelessWidget {
  const StudyStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Hours Overview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Analysis',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'See how your study hours fluctuate over the week.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Consumer<DashboardProvider>(
                  builder: (context, dashboard, _) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withAlpha(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Study Hours',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Icon(Icons.insights_rounded, color: AppTheme.primaryColor),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Expanded(
                            child: LineChart(
                              LineChartData(
                                lineTouchData: LineTouchData(
                                  handleBuiltInTouches: true,
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        return LineTooltipItem(
                                          '${spot.y.toStringAsFixed(1)}h',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 1,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Theme.of(context).colorScheme.primary.withAlpha(15),
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                        final idx = value.toInt();
                                        if (idx < 0 || idx >= days.length) return const Text('');
                                        final isToday = idx == (DateTime.now().weekday - 1);
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            days[idx],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                              color: isToday
                                                  ? AppTheme.primaryColor
                                                  : Theme.of(context).textTheme.bodyMedium?.color,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 32,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${value.toInt()}h',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    isCurved: true,
                                    curveSmoothness: 0.35,
                                    color: AppTheme.primaryColor,
                                    barWidth: 4,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, barData, index) {
                                        final isToday = index == (DateTime.now().weekday - 1);
                                        return FlDotCirclePainter(
                                          radius: isToday ? 6 : 4,
                                          color: isToday ? AppTheme.secondaryColor : AppTheme.primaryColor,
                                          strokeWidth: 2,
                                          strokeColor: Theme.of(context).cardTheme.color ?? Colors.white,
                                        );
                                      },
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor.withAlpha(80),
                                          AppTheme.primaryColor.withAlpha(0),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    spots: List.generate(7, (i) {
                                      return FlSpot(i.toDouble(), dashboard.weeklyData[i]);
                                    }),
                                  ),
                                ],
                                minY: 0,
                                maxY: _getMaxY(dashboard.weeklyData),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getMaxY(List<double> data) {
    final max = data.fold<double>(0, (prev, e) => e > prev ? e : prev);
    return max < 1 ? 4 : (max + 1).ceilToDouble();
  }
}
