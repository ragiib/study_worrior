// ============================================================================
// Database Service - Hive persistence layer (Cross-platform)
// ============================================================================

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/study_session_model.dart';

class DatabaseService {
  bool _initialized = false;
  late Box<String> _tasksBox;
  late Box<String> _habitsBox;
  late Box<String> _sessionsBox;

  bool get isInitialized => _initialized;

  // ── Initialize Database ─────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    
    await Hive.initFlutter();
    
    _tasksBox = await Hive.openBox<String>('tasks');
    _habitsBox = await Hive.openBox<String>('habits');
    _sessionsBox = await Hive.openBox<String>('sessions');
    
    _initialized = true;
  }

  // ══════════════════════════════════════════════════════════════════════
  // TASK OPERATIONS
  // ══════════════════════════════════════════════════════════════════════

  Future<List<Task>> getAllTasks() async {
    if (!_initialized) return [];
    return _tasksBox.values.map((jsonStr) {
      return Task.fromMap(jsonDecode(jsonStr));
    }).toList();
  }

  Future<void> insertTask(Task task) async {
    if (!_initialized) return;
    await _tasksBox.put(task.id, jsonEncode(task.toMap()));
  }

  Future<void> updateTask(Task task) async {
    if (!_initialized) return;
    await _tasksBox.put(task.id, jsonEncode(task.toMap()));
  }

  Future<void> deleteTask(String id) async {
    if (!_initialized) return;
    await _tasksBox.delete(id);
  }

  // ══════════════════════════════════════════════════════════════════════
  // HABIT OPERATIONS
  // ══════════════════════════════════════════════════════════════════════

  Future<List<Habit>> getAllHabits() async {
    if (!_initialized) return [];
    return _habitsBox.values.map((jsonStr) {
      return Habit.fromMap(jsonDecode(jsonStr));
    }).toList();
  }

  Future<void> insertHabit(Habit habit) async {
    if (!_initialized) return;
    await _habitsBox.put(habit.id, jsonEncode(habit.toMap()));
  }

  Future<void> updateHabit(Habit habit) async {
    if (!_initialized) return;
    await _habitsBox.put(habit.id, jsonEncode(habit.toMap()));
  }

  Future<void> deleteHabit(String id) async {
    if (!_initialized) return;
    await _habitsBox.delete(id);
  }

  Future<void> toggleHabitCompletion(String habitId, DateTime date) async {
    if (!_initialized) return;
    final jsonStr = _habitsBox.get(habitId);
    if (jsonStr == null) return;
    
    final habit = Habit.fromMap(jsonDecode(jsonStr));
    habit.toggleCompletion(date);
    await updateHabit(habit);
  }

  // ══════════════════════════════════════════════════════════════════════
  // STUDY SESSION OPERATIONS & ANALYTICS
  // ══════════════════════════════════════════════════════════════════════

  Future<void> insertSession(StudySession session) async {
    if (!_initialized) return;
    await _sessionsBox.put(session.id, jsonEncode(session.toMap()));
  }

  Future<int> getStudyMinutesForDate(DateTime date) async {
    if (!_initialized) return 0;
    
    int totalMinutes = 0;
    for (var jsonStr in _sessionsBox.values) {
      final session = StudySession.fromMap(jsonDecode(jsonStr));
      if (session.date.year == date.year &&
          session.date.month == date.month &&
          session.date.day == date.day) {
        totalMinutes += session.durationMinutes;
      }
    }
    return totalMinutes;
  }

  Future<List<double>> getWeeklyStudyData() async {
    if (!_initialized) return [0, 0, 0, 0, 0, 0, 0];
    
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekData = List<double>.filled(7, 0.0);

    for (var jsonStr in _sessionsBox.values) {
      final session = StudySession.fromMap(jsonDecode(jsonStr));
      // Ensure session is within this week
      final sessionDay = DateTime(session.date.year, session.date.month, session.date.day);
      final mondayDay = DateTime(monday.year, monday.month, monday.day);
      
      final difference = sessionDay.difference(mondayDay).inDays;
      if (difference >= 0 && difference < 7) {
        weekData[difference] += session.durationMinutes / 60.0;
      }
    }
    return weekData;
  }

  Future<List<double>> getWeeklyCompletedTasksData() async {
    if (!_initialized) return [0, 0, 0, 0, 0, 0, 0];
    
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekData = List<double>.filled(7, 0.0);

    for (var jsonStr in _tasksBox.values) {
      final task = Task.fromMap(jsonDecode(jsonStr));
      if (task.isCompleted && task.completedAt != null) {
        final completedDay = DateTime(task.completedAt!.year, task.completedAt!.month, task.completedAt!.day);
        final mondayDay = DateTime(monday.year, monday.month, monday.day);
        
        final difference = completedDay.difference(mondayDay).inDays;
        if (difference >= 0 && difference < 7) {
          weekData[difference] += 1.0;
        }
      }
    }
    return weekData;
  }

  Future<int> getTasksCompletedToday() async {
    if (!_initialized) return 0;
    
    final now = DateTime.now();
    int count = 0;
    
    for (var jsonStr in _tasksBox.values) {
      final task = Task.fromMap(jsonDecode(jsonStr));
      if (task.isCompleted && task.completedAt != null) {
        if (task.completedAt!.year == now.year &&
            task.completedAt!.month == now.month &&
            task.completedAt!.day == now.day) {
          count++;
        }
      }
    }
    return count;
  }

  Future<int> getCurrentStreak() async {
    if (!_initialized) return 0;
    
    // Extract all unique dates where user studied at least 1 minute
    final uniqueStudyDates = <String>{};
    for (var jsonStr in _sessionsBox.values) {
      final session = StudySession.fromMap(jsonDecode(jsonStr));
      if (session.durationMinutes > 0) {
        final dateStr = '${session.date.year}-${session.date.month.toString().padLeft(2, '0')}-${session.date.day.toString().padLeft(2, '0')}';
        uniqueStudyDates.add(dateStr);
      }
    }
    
    // Sort descending
    final sortedDates = uniqueStudyDates.toList()..sort((a, b) => b.compareTo(a));
    
    if (sortedDates.isEmpty) return 0;
    
    int streak = 0;
    DateTime dateToCheck = DateTime.now();
    
    // Handle edge case: User hasn't studied today yet, but has a streak ending yesterday
    final todayStr = '${dateToCheck.year}-${dateToCheck.month.toString().padLeft(2, '0')}-${dateToCheck.day.toString().padLeft(2, '0')}';
    
    if (!uniqueStudyDates.contains(todayStr)) {
      dateToCheck = dateToCheck.subtract(const Duration(days: 1));
    }
    
    while (true) {
      final checkStr = '${dateToCheck.year}-${dateToCheck.month.toString().padLeft(2, '0')}-${dateToCheck.day.toString().padLeft(2, '0')}';
      if (uniqueStudyDates.contains(checkStr)) {
        streak++;
        dateToCheck = dateToCheck.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }
}
