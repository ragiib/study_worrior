// ============================================================================
// Tasks Screen - Full-featured task manager
// Add, edit, delete tasks with priorities, due dates, search, and filters.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/task_provider.dart';
import '../../models/task_model.dart';
import '../theme/app_theme.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Text(
              'Task Manager',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 4),
            Text(
              'Organize your study goals',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 20),

            // ── Search Bar ──────────────────────────────────────────
            _buildSearchBar(context),
            SizedBox(height: 12),

            // ── Filter Chips ────────────────────────────────────────
            _buildFilterChips(context),
            SizedBox(height: 16),

            // ── Task List ───────────────────────────────────────────
            Expanded(child: _buildTaskList(context)),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return TextField(
          onChanged: provider.setSearchQuery,
          decoration: InputDecoration(
            hintText: 'Search tasks...',
            prefixIcon: Icon(Icons.search_rounded),
            suffixIcon: provider.searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded),
                    onPressed: () => provider.setSearchQuery(''),
                  )
                : null,
          ),
        );
      },
    );
  }

  // ── Filter Chips ────────────────────────────────────────────────────
  Widget _buildFilterChips(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: provider.filterPriority == null,
                onTap: () => provider.setFilterPriority(null),
              ),
              SizedBox(width: 8),
              _FilterChip(
                label: '🟢 Low',
                isSelected: provider.filterPriority == TaskPriority.low,
                onTap: () => provider.setFilterPriority(TaskPriority.low),
                color: Colors.green,
              ),
              SizedBox(width: 8),
              _FilterChip(
                label: '🟡 Medium',
                isSelected: provider.filterPriority == TaskPriority.medium,
                onTap: () => provider.setFilterPriority(TaskPriority.medium),
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              _FilterChip(
                label: '🔴 High',
                isSelected: provider.filterPriority == TaskPriority.high,
                onTap: () => provider.setFilterPriority(TaskPriority.high),
                color: Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Task List ───────────────────────────────────────────────────────
  Widget _buildTaskList(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final tasks = provider.tasks;

        Widget content;
        if (tasks.isEmpty) {
          content = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt_rounded,
                  size: 80,
                  color: AppTheme.primaryColor.withAlpha(60),
                ),
                SizedBox(height: 16),
                Text(
                  'No tasks yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color,
                      ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap + to add your first task',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        } else {
          content = ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _TaskCard(
                task: tasks[index],
                onToggle: () => provider.toggleComplete(tasks[index].id),
                onDelete: () => provider.deleteTask(tasks[index].id),
                onEdit: () => _showEditTaskDialog(context, tasks[index]),
              );
            },
          );
        }

        return Stack(
          children: [
            content,
            // FAB
            Positioned(
              bottom: 16,
              right: 0,
              child: FloatingActionButton(
                onPressed: () => _showAddTaskDialog(context),
                child: Icon(Icons.add_rounded, size: 28),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Add Task Dialog ─────────────────────────────────────────────────
  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TaskPriority priority = TaskPriority.medium;
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(80),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'New Task',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(hintText: 'Task title'),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(hintText: 'Description (optional)'),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    SizedBox(height: 16),
                    // Priority selector
                    Text('Priority', style: Theme.of(context).textTheme.labelLarge),
                    SizedBox(height: 8),
                    Row(
                      children: TaskPriority.values.map((p) {
                        final isSelected = p == priority;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => priority = p),
                            child: Container(
                              margin: EdgeInsets.only(right: p != TaskPriority.high ? 8 : 0),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _priorityColor(p).withAlpha(30)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? _priorityColor(p)
                                      : Colors.grey.withAlpha(60),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _priorityLabel(p),
                                  style: TextStyle(
                                    color: isSelected
                                        ? _priorityColor(p)
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    // Due date picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => dueDate = picked);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .inputDecorationTheme
                              .fillColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 20),
                            SizedBox(width: 12),
                            Text(
                              dueDate != null
                                  ? DateFormat('MMM d, yyyy').format(dueDate!)
                                  : 'Set due date (optional)',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          Provider.of<TaskProvider>(context, listen: false)
                              .addTask(
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            priority: priority,
                            dueDate: dueDate,
                          );
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Add Task',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Edit Task Dialog ────────────────────────────────────────────────
  void _showEditTaskDialog(BuildContext context, Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    TaskPriority priority = task.priority;
    DateTime? dueDate = task.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(80),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Edit Task',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(hintText: 'Task title'),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: InputDecoration(hintText: 'Description'),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    Text('Priority', style: Theme.of(context).textTheme.labelLarge),
                    SizedBox(height: 8),
                    Row(
                      children: TaskPriority.values.map((p) {
                        final isSelected = p == priority;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => priority = p),
                            child: Container(
                              margin: EdgeInsets.only(right: p != TaskPriority.high ? 8 : 0),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _priorityColor(p).withAlpha(30)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? _priorityColor(p)
                                      : Colors.grey.withAlpha(60),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _priorityLabel(p),
                                  style: TextStyle(
                                    color: isSelected
                                        ? _priorityColor(p)
                                        : null,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => dueDate = picked);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 20),
                            SizedBox(width: 12),
                            Text(
                              dueDate != null
                                  ? DateFormat('MMM d, yyyy').format(dueDate!)
                                  : 'Set due date',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          final updated = task.copyWith(
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            priority: priority,
                            dueDate: dueDate,
                          );
                          Provider.of<TaskProvider>(context, listen: false)
                              .updateTask(updated);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  static String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Task Card Widget - Individual task display with swipe-to-delete
// ════════════════════════════════════════════════════════════════════════════
class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(40),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_rounded, color: Colors.red),
      ),
      child: GestureDetector(
        onTap: onEdit,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: task.isCompleted
                  ? AppTheme.secondaryColor.withAlpha(60)
                  : _priorityBorderColor(task.priority),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Completion checkbox
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? AppTheme.secondaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: task.isCompleted
                          ? AppTheme.secondaryColor
                          : Colors.grey.withAlpha(100),
                      width: 2,
                    ),
                  ),
                  child: task.isCompleted
                      ? Icon(Icons.check_rounded,
                          size: 18, color: Colors.white)
                      : null,
                ),
              ),
              SizedBox(width: 14),
              // Task details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                            : Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.color,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        task.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (task.dueDate != null) ...[
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: _isDueSoon(task.dueDate!)
                                ? Colors.red
                                : Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                          ),
                          SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d').format(task.dueDate!),
                            style: TextStyle(
                              fontSize: 11,
                              color: _isDueSoon(task.dueDate!)
                                  ? Colors.red
                                  : Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Priority indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _priorityBgColor(task.priority),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.priorityLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _priorityTextColor(task.priority),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDueSoon(DateTime date) {
    return date.difference(DateTime.now()).inDays <= 1;
  }

  Color _priorityBorderColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return Colors.green.withAlpha(40);
      case TaskPriority.medium:
        return Colors.orange.withAlpha(40);
      case TaskPriority.high:
        return Colors.red.withAlpha(40);
    }
  }

  Color _priorityBgColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return Colors.green.withAlpha(25);
      case TaskPriority.medium:
        return Colors.orange.withAlpha(25);
      case TaskPriority.high:
        return Colors.red.withAlpha(25);
    }
  }

  Color _priorityTextColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Filter Chip Widget
// ════════════════════════════════════════════════════════════════════════════
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppTheme.primaryColor).withAlpha(25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? AppTheme.primaryColor)
                : Colors.grey.withAlpha(60),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (color ?? AppTheme.primaryColor)
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
