// ============================================================================
// Dashboard Provider - Aggregates stats for the dashboard screen
// Loads daily study hours, completed tasks, streak, and weekly chart data.
// ============================================================================

import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DatabaseService _db;

  double _todayStudyHours = 0;
  int _tasksCompleted = 0;
  int _currentStreak = 0;
  List<double> _weeklyData = [0, 0, 0, 0, 0, 0, 0];
  List<double> _weeklyTasksData = [0, 0, 0, 0, 0, 0, 0];

  DashboardProvider(this._db);

  // ── Getters ─────────────────────────────────────────────────────────
  double get todayStudyHours => _todayStudyHours;
  int get tasksCompleted => _tasksCompleted;
  int get currentStreak => _currentStreak;
  List<double> get weeklyData => _weeklyData;
  List<double> get weeklyTasksData => _weeklyTasksData;

  // ── Load all dashboard stats ────────────────────────────────────────
  Future<void> loadStats() async {
    final todayMinutes = await _db.getStudyMinutesForDate(DateTime.now());
    _todayStudyHours = todayMinutes / 60.0;

    _tasksCompleted = await _db.getTasksCompletedToday();
    _currentStreak = await _db.getCurrentStreak();
    _weeklyData = await _db.getWeeklyStudyData();
    _weeklyTasksData = await _db.getWeeklyCompletedTasksData();

    notifyListeners();
  }

  // ── Record a completed study session ────────────────────────────────
  void recordSession(int minutes) {
    _todayStudyHours += minutes / 60.0;
    notifyListeners();
    // Reload to update all derived stats
    loadStats();
  }
}
