// ============================================================================
// Dashboard Screen - Study analytics overview
// Displays stat cards (study hours, tasks, streak) and weekly progress chart.
// Features premium gradient cards and animated bar chart.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/dashboard_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'detailed_stats_screen.dart';
import 'settings_screen.dart';
import 'saved_notes_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () =>
            Provider.of<DashboardProvider>(context, listen: false).loadStats(),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              _buildHeader(context),
              SizedBox(height: 24),

              // ── Stats Cards Row ─────────────────────────────────────
              _buildStatsRow(context),
              SizedBox(height: 24),

              // ── Weekly Progress Chart ───────────────────────────────
              _buildWeeklyChart(context),
              SizedBox(height: 24),

              // ── Quick Actions ───────────────────────────────────────
              _buildQuickActions(context),
              SizedBox(height: 24),

              // ── Task Progress ──────────────────────────────────────
              _buildTaskProgress(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header with greeting ────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    if (hour < 12) {
      greeting = 'Good Morning';
      emoji = '🌅';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      emoji = '☀️';
    } else {
      greeting = 'Good Evening';
      emoji = '🌙';
    }

    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      greeting.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: Text(
                  'STUDY WARRIOR',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 34,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your journey to excellence starts here',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
              icon: const Icon(Icons.settings_outlined),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: CircleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Cards ─────────────────────────────────────────────────────
  Widget _buildStatsRow(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final taskProvider = Provider.of<TaskProvider>(context);
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Study Hours',
                    value: dashboard.todayStudyHours.toStringAsFixed(1),
                    subtitle: 'Today',
                    icon: Icons.schedule_rounded,
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailedStatsScreen(
                            title: 'Study Hours Overview',
                            description: 'See how your study hours fluctuate over the week.',
                            chartTitle: 'Study Hours',
                            unit: 'h',
                            data: dashboard.weeklyData,
                            primaryColor: AppTheme.primaryColor,
                            secondaryColor: AppTheme.secondaryColor,
                            icon: Icons.insights_rounded,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Completed',
                    value: '${taskProvider.completedTasksToday}',
                    subtitle: 'Tasks done',
                    icon: Icons.check_circle_outline_rounded,
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailedStatsScreen(
                            title: 'Tasks Completed Overview',
                            description: 'See how many tasks you\'ve completed over the week.',
                            chartTitle: 'Tasks Completed',
                            unit: '',
                            data: dashboard.weeklyTasksData,
                            primaryColor: Colors.green,
                            secondaryColor: Colors.lightGreen,
                            icon: Icons.task_alt_rounded,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Streak',
                    value: '${dashboard.currentStreak}',
                    subtitle: 'Days',
                    icon: Icons.local_fire_department_rounded,
                    gradient: LinearGradient(
                      colors: [Color(0xFFF43F5E), Color(0xFFBE123C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pending',
                    value: '${taskProvider.totalTasksToday - taskProvider.completedTasksToday}',
                    subtitle: 'Tasks left',
                    icon: Icons.pending_actions_rounded,
                    gradient: LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      if (onNavigate != null) onNavigate!(1);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ── Task Progress ───────────────────────────────────────────────────
  Widget _buildTaskProgress(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final progress = taskProvider.todayProgress;
        final completed = taskProvider.completedTasksToday;
        final total = taskProvider.totalTasksToday;

        if (total == 0) return SizedBox.shrink();

        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Tasks",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '$completed/$total',
                    style: TextStyle(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(20),
                  valueColor: AlwaysStoppedAnimation(AppTheme.secondaryColor),
                ),
              ),
              SizedBox(height: 8),
              Text(
                taskProvider.tasks.isEmpty
                    ? 'Add tasks to start tracking!'
                    : '${(progress * 100).toInt()}% complete today',
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Weekly Progress Bar Chart ───────────────────────────────────────
  Widget _buildWeeklyChart(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Weekly Progress',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'This Week',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(dashboard.weeklyData),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toStringAsFixed(1)}h',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}h',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            final idx = value.toInt();
                            if (idx < 0 || idx >= days.length) return Text('');
                            final isToday = idx == (DateTime.now().weekday - 1);
                            return Text(
                              days[idx],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                                color: isToday
                                    ? AppTheme.primaryColor
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(15),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(7, (i) {
                      final isToday = i == (DateTime.now().weekday - 1);
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: dashboard.weeklyData[i],
                            width: 24,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            gradient: isToday
                                ? AppTheme.primaryGradient
                                : LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor.withAlpha(100),
                                      AppTheme.primaryColor.withAlpha(60),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                          ),
                        ],
                      );
                    }),
                  ),
                  swapAnimationDuration: Duration(milliseconds: 500),
                  swapAnimationCurve: Curves.easeInOut,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _getMaxY(List<double> data) {
    final max = data.fold<double>(0, (prev, e) => e > prev ? e : prev);
    return max < 1 ? 4 : (max + 1).ceilToDouble();
  }

  // ── Quick Action Buttons ────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _QuickActionButton(
              icon: Icons.workspace_premium_rounded,
              label: 'Premium Tools',
              color: Colors.purpleAccent,
              onTap: () {
                if (onNavigate != null) onNavigate!(4);
              },
            ),
            SizedBox(width: 8),
            _QuickActionButton(
              icon: Icons.add_task_rounded,
              label: 'Add Task',
              color: AppTheme.primaryColor,
              onTap: () {
                if (onNavigate != null) onNavigate!(1);
              },
            ),
            SizedBox(width: 8),
            _QuickActionButton(
              icon: Icons.play_arrow_rounded,
              label: 'Timer',
              color: AppTheme.secondaryColor,
              onTap: () {
                if (onNavigate != null) onNavigate!(2);
              },
            ),
            SizedBox(width: 8),
            _QuickActionButton(
              icon: Icons.check_rounded,
              label: 'Log Task',
              color: AppTheme.accentOrange,
              onTap: () {
                if (onNavigate != null) onNavigate!(1);
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Stat Card Widget - Gradient card with icon, value, and label
// ════════════════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withAlpha(50),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withAlpha(200), size: 28),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withAlpha(160),
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Quick Action Button - Circular icon button with label
// ════════════════════════════════════════════════════════════════════════════
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

