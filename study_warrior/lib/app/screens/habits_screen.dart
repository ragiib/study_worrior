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
  bool _showOnlyToday = true;

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

                // ── Toggle Switch ───────────────────────────────────────────
                Row(
                  children: [
                    _buildToggleChip('Today', _showOnlyToday, () {
                      setState(() => _showOnlyToday = true);
                    }),
                    SizedBox(width: 8),
                    _buildToggleChip('All Habits', !_showOnlyToday, () {
                      setState(() => _showOnlyToday = false);
                    }),
                  ],
                ),
                SizedBox(height: 20),

                // ── Habit List & Calendar ────────────────────────────────
            Expanded(
              child: Consumer<HabitProvider>(
                builder: (context, habitProvider, _) {
                  var displayHabits = habitProvider.habits;
                  if (_showOnlyToday) {
                    displayHabits = displayHabits
                        .where((h) => h.isScheduledFor(DateTime.now()))
                        .toList();
                  }

                  if (displayHabits.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView(
                    children: [
                      // Habits list
                      ...displayHabits.map(
                        (habit) => _HabitCard(
                          habit: habit,
                          isSelected: _selectedHabitId == habit.id,
                          onToggle: () {
                            if (habit.isScheduledFor(DateTime.now())) {
                              habitProvider.toggleHabitToday(habit.id);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('This habit is not scheduled for today.'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          onDelete: () => habitProvider.deleteHabit(habit.id),
                          onEdit: () => _showHabitDialog(context, habit),
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
              onPressed: () => _showHabitDialog(context),
              child: Icon(Icons.add_rounded, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.withAlpha(60),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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
                } else if (!habit.isScheduledFor(day)) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(80),
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

  // ── Add/Edit Habit Dialog ───────────────────────────────────────────
  void _showHabitDialog(BuildContext context, [Habit? habit]) {
    final isEditing = habit != null;
    final nameController = TextEditingController(text: isEditing ? habit.name : '');
    final descController = TextEditingController(text: isEditing ? habit.description : '');
    String selectedEmoji = isEditing ? habit.emoji : '📚';
    List<int> selectedDays = isEditing ? List.from(habit.scheduledDays) : [1, 2, 3, 4, 5, 6, 7];

    final emojis = [
      '📚', '💪', '🧘', '🏃', '💧', '🎯', '✍️', '🎵',
      '🌅', '📖', '🧠', '🍎', '😴', '🔬', '💻', '🎨',
    ];

    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return AnimatedPadding(
              duration: Duration(milliseconds: 100),
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                        isEditing ? 'Edit Habit' : 'New Habit',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(hintText: 'Habit name'),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        decoration: InputDecoration(
                          hintText: 'Description (optional)',
                          hintStyle: TextStyle(fontSize: 14),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        minLines: 1,
                      ),
                      SizedBox(height: 16),
                      
                      // Weekday Selector
                      Text('Scheduled Days', style: Theme.of(context).textTheme.labelLarge),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          final dayNum = index + 1;
                          final isSelected = selectedDays.contains(dayNum);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected && selectedDays.length > 1) {
                                  selectedDays.remove(dayNum);
                                } else if (!isSelected) {
                                  selectedDays.add(dayNum);
                                }
                              });
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryColor : Colors.grey.withAlpha(60),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  weekdays[index],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      
                      SizedBox(height: 16),
                      Text('Choose an emoji', style: Theme.of(context).textTheme.labelLarge),
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
                            
                            if (isEditing) {
                              habit.name = nameController.text.trim();
                              habit.description = descController.text.trim();
                              habit.emoji = selectedEmoji;
                              habit.scheduledDays = selectedDays;
                              Provider.of<HabitProvider>(context, listen: false).updateHabit(habit);
                            } else {
                              Provider.of<HabitProvider>(context, listen: false).addHabit(
                                name: nameController.text.trim(),
                                description: descController.text.trim(),
                                emoji: selectedEmoji,
                                scheduledDays: selectedDays,
                              );
                            }
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
                            isEditing ? 'Save Changes' : 'Add Habit',
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
  final VoidCallback onEdit;
  final VoidCallback onTapCalendar;

  const _HabitCard({
    required this.habit,
    required this.isSelected,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    required this.onTapCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final isScheduledToday = habit.isScheduledFor(DateTime.now());

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
                    : isScheduledToday ? Colors.transparent : Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: habit.isCompletedToday
                      ? AppTheme.secondaryColor
                      : isScheduledToday ? Colors.grey.withAlpha(60) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  habit.emoji,
                  style: TextStyle(
                    fontSize: 22,
                    color: isScheduledToday ? null : Colors.grey.withAlpha(100),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 14),
          // Habit details (Tappable to show Calendar)
          Expanded(
            child: GestureDetector(
              onTap: onTapCalendar,
              behavior: HitTestBehavior.opaque,
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
                  if (habit.description.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      habit.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                ],
              ),
            ),
          ),
          // More actions menu
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
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
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
