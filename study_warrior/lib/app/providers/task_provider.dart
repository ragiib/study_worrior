// ============================================================================
// Task Provider - State management for task CRUD operations
// Supports search, filter by priority, and sort operations.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/task_model.dart';
import '../../services/database_service.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseService _db;
  List<Task> _tasks = [];
  String _searchQuery = '';
  TaskPriority? _filterPriority;

  TaskProvider(this._db);

  // ── Getters ─────────────────────────────────────────────────────────
  List<Task> get allTasks => _tasks;

  /// Filtered + searched tasks for display
  List<Task> get tasks {
    var filtered = List<Task>.from(_tasks);

    // Apply priority filter
    if (_filterPriority != null) {
      filtered = filtered.where((t) => t.priority == _filterPriority).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((t) =>
              t.title.toLowerCase().contains(query) ||
              t.description.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  String get searchQuery => _searchQuery;
  TaskPriority? get filterPriority => _filterPriority;

  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingCount => _tasks.where((t) => !t.isCompleted).length;

  // ── Load tasks from database ────────────────────────────────────────
  Future<void> loadTasks() async {
    _tasks = await _db.getAllTasks();
    notifyListeners();
  }

  // ── Add a new task ──────────────────────────────────────────────────
  Future<void> addTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
    );
    await _db.insertTask(task);
    _tasks.insert(0, task);
    notifyListeners();
  }

  // ── Update an existing task ─────────────────────────────────────────
  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  // ── Toggle task completion ──────────────────────────────────────────
  Future<void> toggleComplete(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final task = _tasks[index];
      final isNowCompleted = !task.isCompleted;
      
      final updated = task.copyWith(
        isCompleted: isNowCompleted,
        completedAt: isNowCompleted ? DateTime.now() : null,
        clearCompletedAt: !isNowCompleted,
      );
      
      _tasks[index] = updated;
      notifyListeners();

      await _db.updateTask(updated);
    }
  }

  // ── Delete a task ───────────────────────────────────────────────────
  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ── Search & Filter ─────────────────────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterPriority(TaskPriority? priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterPriority = null;
    notifyListeners();
  }
}
