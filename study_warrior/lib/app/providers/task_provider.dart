// ============================================================================
// Task Provider - State management for recurring task tracking
// Manages task CRUD, daily completion toggling, and streak calculation.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/task_model.dart';
import '../../services/database_service.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<Task> _tasks = [];

  TaskProvider(this._db);

  List<Task> get tasks => _tasks;

  int get totalTasksToday => _tasks.where((h) => h.isScheduledFor(DateTime.now())).length;
  int get completedTasksToday =>
      _tasks.where((h) => h.isScheduledFor(DateTime.now()) && h.isCompletedToday).length;

  double get todayProgress {
    final total = totalTasksToday;
    if (total == 0) return 0;
    return completedTasksToday / total;
  }

  // ── Load tasks from database ───────────────────────────────────────
  Future<void> loadTasks() async {
    _tasks = await _db.getAllTasks();
    _recalculateStreaks();
    notifyListeners();
  }

  // ── Add new task ───────────────────────────────────────────────────
  Future<void> addTask({
    required String name,
    String description = '',
    String emoji = '📚',
    List<int> scheduledDays = const [1, 2, 3, 4, 5, 6, 7],
  }) async {
    final task = Task(
      id: const Uuid().v4(),
      name: name,
      description: description,
      emoji: emoji,
      scheduledDays: scheduledDays,
    );
    await _db.insertTask(task);
    _tasks.insert(0, task);
    notifyListeners();
  }

  // ── Update task ────────────────────────────────────────────────────
  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    final index = _tasks.indexWhere((h) => h.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _recalculateStreaks();
      notifyListeners();
    }
  }

  // ── Delete task ────────────────────────────────────────────────────
  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
    _tasks.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  // ── Toggle task completion for today ───────────────────────────────
  Future<void> toggleTaskToday(String id) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _db.toggleTaskCompletion(id, today);

    // Update local state
    final task = _tasks.firstWhere((h) => h.id == id);
    if (task.isCompletedOn(today)) {
      task.completedDates.removeWhere(
        (d) => d.year == today.year && d.month == today.month && d.day == today.day,
      );
    } else {
      task.completedDates.add(today);
    }

    _recalculateStreaks();
    notifyListeners();
  }

  // ── Recalculate streaks for all tasks ──────────────────────────────
  void _recalculateStreaks() {
    for (final task in _tasks) {
      int streak = 0;
      DateTime checkDate = DateTime.now();

      // Skip today if it's not scheduled, or if it's scheduled but not yet completed
      if (!task.isScheduledFor(checkDate) || !task.isCompletedOn(checkDate)) {
        checkDate = checkDate.subtract(Duration(days: 1));
      }

      while (true) {
        if (!task.isScheduledFor(checkDate)) {
          // Skip days where the task is not scheduled
          checkDate = checkDate.subtract(Duration(days: 1));
          continue;
        }

        if (task.isCompletedOn(checkDate)) {
          streak++;
          checkDate = checkDate.subtract(Duration(days: 1));
        } else {
          // Missed a scheduled day! Streak broken.
          break;
        }
      }

      // Add 1 if today was completed
      if (task.isScheduledFor(DateTime.now()) && task.isCompletedToday) {
        streak++;
      }

      task.currentStreak = streak;
      if (streak > task.longestStreak) {
        task.longestStreak = streak;
      }

      // Persist updated streak values
      _db.updateTask(task);
    }
  }
}
