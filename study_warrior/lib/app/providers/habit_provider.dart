// ============================================================================
// Habit Provider - State management for habit tracking
// Manages habit CRUD, daily completion toggling, and streak calculation.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/habit_model.dart';
import '../../services/database_service.dart';

class HabitProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<Habit> _habits = [];

  HabitProvider(this._db);

  List<Habit> get habits => _habits;

  int get totalHabitsToday => _habits.length;
  int get completedHabitsToday =>
      _habits.where((h) => h.isCompletedToday).length;

  double get todayProgress {
    if (_habits.isEmpty) return 0;
    return completedHabitsToday / totalHabitsToday;
  }

  // ── Load habits from database ───────────────────────────────────────
  Future<void> loadHabits() async {
    _habits = await _db.getAllHabits();
    _recalculateStreaks();
    notifyListeners();
  }

  // ── Add new habit ───────────────────────────────────────────────────
  Future<void> addHabit({required String name, String emoji = '📚'}) async {
    final habit = Habit(
      id: const Uuid().v4(),
      name: name,
      emoji: emoji,
    );
    await _db.insertHabit(habit);
    _habits.insert(0, habit);
    notifyListeners();
  }

  // ── Delete habit ────────────────────────────────────────────────────
  Future<void> deleteHabit(String id) async {
    await _db.deleteHabit(id);
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  // ── Toggle habit completion for today ───────────────────────────────
  Future<void> toggleHabitToday(String id) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _db.toggleHabitCompletion(id, today);

    // Update local state
    final habit = _habits.firstWhere((h) => h.id == id);
    if (habit.isCompletedOn(today)) {
      habit.completedDates.removeWhere(
        (d) => d.year == today.year && d.month == today.month && d.day == today.day,
      );
    } else {
      habit.completedDates.add(today);
    }

    _recalculateStreaks();
    notifyListeners();
  }

  // ── Recalculate streaks for all habits ──────────────────────────────
  void _recalculateStreaks() {
    for (final habit in _habits) {
      int streak = 0;
      DateTime checkDate = DateTime.now();

      // Check today first
      if (!habit.isCompletedOn(checkDate)) {
        // Allow checking from yesterday if today isn't done yet
        checkDate = checkDate.subtract(Duration(days: 1));
      }

      while (habit.isCompletedOn(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(Duration(days: 1));
      }

      habit.currentStreak = streak;
      if (streak > habit.longestStreak) {
        habit.longestStreak = streak;
      }

      // Persist updated streak values
      _db.updateHabit(habit);
    }
  }
}
