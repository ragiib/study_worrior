// ============================================================================
// Pomodoro Screen - Focus timer with circular progress
// Supports 25/5 and custom durations, start/pause/resume/reset.
// Features a beautiful circular animated progress indicator.
// ============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pomodoro_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_page_header.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Consumer<PomodoroProvider>(
          builder: (context, pomodoro, _) {
            return Column(
              children: [
                // ── Header ────────────────────────────────────────────
                const SizedBox(height: 10),
                PremiumPageHeader(
                  topLabel: pomodoro.isBreak ? 'Break Time' : 'Focus Mode',
                  emoji: pomodoro.isBreak ? '☕' : '🎯',
                  title: 'Pomodoro',
                  subtitle: pomodoro.isBreak
                      ? 'Take a well-deserved rest'
                      : 'Stay focused, warrior!',
                ),
                SizedBox(height: 40),

                // ── Circular Timer ────────────────────────────────────
                _buildCircularTimer(context, pomodoro),
                SizedBox(height: 40),

                // ── Control Buttons ───────────────────────────────────
                _buildControls(context, pomodoro),
                SizedBox(height: 36),

                // ── Session Counter ───────────────────────────────────
                _buildSessionCounter(context, pomodoro),
                SizedBox(height: 24),

                // ── Duration Presets ──────────────────────────────────
                _buildPresets(context, pomodoro),
                SizedBox(height: 20),

                // ── Custom Duration Sliders ───────────────────────────
                _buildCustomDuration(context, pomodoro),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Circular Timer Widget ───────────────────────────────────────────
  Widget _buildCircularTimer(BuildContext context, PomodoroProvider pomodoro) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardTheme.color,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withAlpha(20),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          // Progress ring
          SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: pomodoro.progress,
                isBreak: pomodoro.isBreak,
                strokeWidth: 8,
              ),
            ),
          ),
          // Timer display
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pomodoro.timeDisplay,
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: Theme.of(context).textTheme.headlineLarge?.color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _stateLabel(pomodoro),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: pomodoro.isBreak
                      ? AppTheme.secondaryColor
                      : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _stateLabel(PomodoroProvider p) {
    if (p.isBreak && p.state == PomodoroState.breakTime) return 'Start Break';
    if (p.isBreak && p.isRunning) return 'On Break';
    if (p.isRunning) return 'Focusing...';
    if (p.isPaused) return 'Paused';
    return 'Ready';
  }

  // ── Control Buttons ─────────────────────────────────────────────────
  Widget _buildControls(BuildContext context, PomodoroProvider pomodoro) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset button
        if (!pomodoro.isIdle)
          _ControlButton(
            icon: Icons.refresh_rounded,
            label: 'Reset',
            color: AppTheme.accentOrange,
            onTap: pomodoro.reset,
          ),
        if (!pomodoro.isIdle) SizedBox(width: 24),

        // Main play/pause button
        GestureDetector(
          onTap: () {
            if (pomodoro.state == PomodoroState.breakTime) {
              pomodoro.startBreak();
            } else if (pomodoro.isRunning) {
              pomodoro.pause();
            } else {
              pomodoro.start();
            }
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: pomodoro.isBreak
                  ? AppTheme.successGradient
                  : AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (pomodoro.isBreak
                          ? AppTheme.secondaryColor
                          : AppTheme.primaryColor)
                      .withAlpha(80),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              pomodoro.isRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),

        // Skip break button (shown during break)
        if (pomodoro.state == PomodoroState.breakTime ||
            (pomodoro.isBreak && pomodoro.isRunning)) ...[
          SizedBox(width: 24),
          _ControlButton(
            icon: Icons.skip_next_rounded,
            label: 'Skip',
            color: AppTheme.accentPurple,
            onTap: pomodoro.skipBreak,
          ),
        ],
      ],
    );
  }

  // ── Session Counter ─────────────────────────────────────────────────
  Widget _buildSessionCounter(
      BuildContext context, PomodoroProvider pomodoro) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded,
              color: AppTheme.accentYellow, size: 24),
          SizedBox(width: 12),
          Text(
            '${pomodoro.completedSessions} sessions completed',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ── Duration Presets (25/5, 50/10, etc.) ────────────────────────────
  Widget _buildPresets(BuildContext context, PomodoroProvider pomodoro) {
    final presets = [
      {'label': '25/5', 'work': 25, 'break': 5},
      {'label': '30/5', 'work': 30, 'break': 5},
      {'label': '45/10', 'work': 45, 'break': 10},
      {'label': '50/10', 'work': 50, 'break': 10},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Presets',
            style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 12),
        Row(
          children: presets.map((preset) {
            final isSelected = pomodoro.workMinutes == preset['work'] &&
                pomodoro.breakMinutes == preset['break'];
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (pomodoro.isIdle) {
                    pomodoro.setWorkMinutes(preset['work'] as int);
                    pomodoro.setBreakMinutes(preset['break'] as int);
                  }
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withAlpha(25)
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      preset['label'] as String,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.primaryColor : null,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Custom Duration Sliders ─────────────────────────────────────────
  Widget _buildCustomDuration(
      BuildContext context, PomodoroProvider pomodoro) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Custom Duration',
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 16),
          // Work duration slider
          Row(
            children: [
              Icon(Icons.work_rounded,
                  size: 20, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Work: ${pomodoro.workMinutes} min'),
            ],
          ),
          Slider(
            value: pomodoro.workMinutes.toDouble(),
            min: 5,
            max: 90,
            divisions: 17,
            activeColor: AppTheme.primaryColor,
            onChanged: pomodoro.isIdle
                ? (v) => pomodoro.setWorkMinutes(v.round())
                : null,
          ),
          // Break duration slider
          Row(
            children: [
              Icon(Icons.coffee_rounded,
                  size: 20, color: AppTheme.secondaryColor),
              SizedBox(width: 8),
              Text('Break: ${pomodoro.breakMinutes} min'),
            ],
          ),
          Slider(
            value: pomodoro.breakMinutes.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: AppTheme.secondaryColor,
            onChanged: pomodoro.isIdle
                ? (v) => pomodoro.setBreakMinutes(v.round())
                : null,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Control Button Widget
// ════════════════════════════════════════════════════════════════════════════
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Circular Progress Painter - Custom paint for the timer ring
// ════════════════════════════════════════════════════════════════════════════
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isBreak;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.isBreak,
    this.strokeWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = (isBreak ? AppTheme.secondaryColor : AppTheme.primaryColor)
          .withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: isBreak
            ? [AppTheme.secondaryColor, Color(0xFF00B894)]
            : [AppTheme.primaryColor, AppTheme.accentPurple],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    // Glow dot at the end of the progress arc
    if (progress > 0) {
      final angle = -pi / 2 + 2 * pi * progress;
      final dotCenter = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      final dotPaint = Paint()
        ..color = isBreak ? AppTheme.secondaryColor : AppTheme.primaryColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(dotCenter, strokeWidth / 2 + 2, dotPaint);

      // Glow effect
      final glowPaint = Paint()
        ..color =
            (isBreak ? AppTheme.secondaryColor : AppTheme.primaryColor)
                .withAlpha(50)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(dotCenter, strokeWidth + 4, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isBreak != isBreak;
  }
}
