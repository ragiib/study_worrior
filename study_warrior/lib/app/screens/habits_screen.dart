// ============================================================================
// Habits Screen - Daily habit tracker with calendar view
// Shows habits with streak counting and a calendar heat map.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/habit_provider.dart';
import '../../models/habit_model.dart';
import '../theme/app_theme.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedHabitId; // Track which habit's calendar to show

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Habit Tracker',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Build consistency daily',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // ── Habit List & Calendar ────────────────────────────────
            Expanded(
              child: Consumer<HabitProvider>(
                builder: (context, habitProvider, _) {
                  if (habitProvider.habits.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView(
                    children: [
                      // Habits list
                      ...habitProvider.habits.map(
                        (habit) => _HabitCard(
                          habit: habit,
                          isSelected: _selectedHabitId == habit.id,
                          onToggle: () =>
                              habitProvider.toggleHabitToday(habit.id),
                          onDelete: () =>
                              habitProvider.deleteHabit(habit.id),
                          onTapCalendar: () {
                            setState(() {
                              _selectedHabitId =
                                  _selectedHabitId == habit.id
                                      ? null
                                      : habit.id;
                            });
                          },
                        ),
                      ),

                      // Calendar view for selected habit
                      if (_selectedHabitId != null) ...[
                        SizedBox(height: 16),
                        _buildCalendarView(context, habitProvider),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _showAddHabitDialog(context),
              child: Icon(Icons.add_rounded, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 80,
            color: AppTheme.accentYellow.withAlpha(100),
          ),
          SizedBox(height: 16),
          Text(
            'No habits yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
          ),
          SizedBox(height: 8),
          Text(
            'Start building powerful daily habits!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ── Calendar View (for a selected habit) ────────────────────────────
  Widget _buildCalendarView(
      BuildContext context, HabitProvider habitProvider) {
    final habit = habitProvider.habits.firstWhere(
      (h) => h.id == _selectedHabitId,
      orElse: () => Habit(id: '', name: ''),
    );
    if (habit.id.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(habit.emoji, style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                '${habit.name} Calendar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          SizedBox(height: 8),
          TableCalendar(
            firstDay: DateTime.now().subtract(Duration(days: 365)),
            lastDay: DateTime.now().add(Duration(days: 30)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(60),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (habit.isCompletedOn(day)) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
              defaultBuilder: (context, day, focusedDay) {
                if (habit.isCompletedOn(day)) {
                  return Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: AppTheme.secondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Add Habit Dialog ────────────────────────────────────────────────
  void _showAddHabitDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedEmoji = '📚';

    final emojis = [
      '📚', '💪', '🧘', '🏃', '💧', '🎯', '✍️', '🎵',
      '🌅', '📖', '🧠', '🍎', '😴', '🔬', '💻', '🎨',
    ];

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    'New Habit',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(hintText: 'Habit name'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  SizedBox(height: 16),
                  Text('Choose an emoji',
                      style: Theme.of(context).textTheme.labelLarge),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emojis.map((emoji) {
                      final isSelected = emoji == selectedEmoji;
                      return GestureDetector(
                        onTap: () => setState(() => selectedEmoji = emoji),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withAlpha(30)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.withAlpha(40),
                            ),
                          ),
                          child: Center(
                            child: Text(emoji, style: TextStyle(fontSize: 22)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;
                        Provider.of<HabitProvider>(context, listen: false)
                            .addHabit(
                          name: nameController.text.trim(),
                          emoji: selectedEmoji,
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
                        'Add Habit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Habit Card Widget
// ════════════════════════════════════════════════════════════════════════════
class _HabitCard extends StatelessWidget {
  final Habit habit;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTapCalendar;

  const _HabitCard({
    required this.habit,
    required this.isSelected,
    required this.onToggle,
    required this.onDelete,
    required this.onTapCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: habit.isCompletedToday
              ? AppTheme.secondaryColor.withAlpha(60)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Completion toggle
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: habit.isCompletedToday
                    ? AppTheme.secondaryColor.withAlpha(25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: habit.isCompletedToday
                      ? AppTheme.secondaryColor
                      : Colors.grey.withAlpha(60),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  habit.emoji,
                  style: TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),
          SizedBox(width: 14),
          // Habit details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: habit.isCompletedToday
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 14, color: AppTheme.accentOrange),
                    SizedBox(width: 4),
                    Text(
                      '${habit.currentStreak} day streak',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.accentOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.emoji_events_rounded,
                        size: 14, color: AppTheme.accentYellow),
                    SizedBox(width: 4),
                    Text(
                      'Best: ${habit.longestStreak}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Calendar button
          IconButton(
            onPressed: onTapCalendar,
            icon: Icon(
              Icons.calendar_month_rounded,
              color: isSelected
                  ? AppTheme.primaryColor
                  : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          // Delete button
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Delete Habit'),
                  content: Text(
                      'Are you sure you want to delete "${habit.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        onDelete();
                        Navigator.pop(ctx);
                      },
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
