// ============================================================================
// Detailed Stats Screen - Generic graph screen for different metrics
// ============================================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/premium_page_header.dart';

class DetailedStatsScreen extends StatelessWidget {
  final String title;
  final String description;
  final String chartTitle;
  final String unit;
  final List<double> data;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;

  const DetailedStatsScreen({
    super.key,
    required this.title,
    required this.description,
    required this.chartTitle,
    required this.unit,
    required this.data,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              PremiumPageHeader(
                topLabel: 'Analytics',
                emoji: '📈',
                title: title,
                subtitle: description,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withAlpha(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            chartTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Icon(icon, color: primaryColor),
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
                                      '${spot.y.toStringAsFixed(unit == '' ? 0 : 1)}$unit',
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
                                  color: primaryColor.withAlpha(15),
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
                                              ? primaryColor
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
                                      '${value.toInt()}$unit',
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
                                color: primaryColor,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    final isToday = index == (DateTime.now().weekday - 1);
                                    return FlDotCirclePainter(
                                      radius: isToday ? 6 : 4,
                                      color: isToday ? secondaryColor : primaryColor,
                                      strokeWidth: 2,
                                      strokeColor: Theme.of(context).cardTheme.color ?? Colors.white,
                                    );
                                  },
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor.withAlpha(80),
                                      primaryColor.withAlpha(0),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                spots: List.generate(7, (i) {
                                  return FlSpot(i.toDouble(), data[i]);
                                }),
                              ),
                            ],
                            minY: 0,
                            maxY: _getMaxY(data),
                          ),
                        ),
                      ),
                    ],
                  ),
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
