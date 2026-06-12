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

  int get totalHabitsToday => _habits.where((h) => h.isScheduledFor(DateTime.now())).length;
  int get completedHabitsToday =>
      _habits.where((h) => h.isScheduledFor(DateTime.now()) && h.isCompletedToday).length;

  double get todayProgress {
    final total = totalHabitsToday;
    if (total == 0) return 0;
    return completedHabitsToday / total;
  }

  // ── Load habits from database ───────────────────────────────────────
  Future<void> loadHabits() async {
    _habits = await _db.getAllHabits();
    _recalculateStreaks();
    notifyListeners();
  }

  // ── Add new habit ───────────────────────────────────────────────────
  Future<void> addHabit({
    required String name,
    String description = '',
    String emoji = '📚',
    List<int> scheduledDays = const [1, 2, 3, 4, 5, 6, 7],
  }) async {
    final habit = Habit(
      id: const Uuid().v4(),
      name: name,
      description: description,
      emoji: emoji,
      scheduledDays: scheduledDays,
    );
    await _db.insertHabit(habit);
    _habits.insert(0, habit);
    notifyListeners();
  }

  // ── Update habit ────────────────────────────────────────────────────
  Future<void> updateHabit(Habit habit) async {
    await _db.updateHabit(habit);
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      _recalculateStreaks();
      notifyListeners();
    }
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

      // Skip today if it's not scheduled, or if it's scheduled but not yet completed
      if (!habit.isScheduledFor(checkDate) || !habit.isCompletedOn(checkDate)) {
        checkDate = checkDate.subtract(Duration(days: 1));
      }

      while (true) {
        if (!habit.isScheduledFor(checkDate)) {
          // Skip days where the habit is not scheduled
          checkDate = checkDate.subtract(Duration(days: 1));
          continue;
        }

        if (habit.isCompletedOn(checkDate)) {
          streak++;
          checkDate = checkDate.subtract(Duration(days: 1));
        } else {
          // Missed a scheduled day! Streak broken.
          break;
        }
      }

      // Add 1 if today was completed
      if (habit.isScheduledFor(DateTime.now()) && habit.isCompletedToday) {
        streak++;
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
