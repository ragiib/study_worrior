// ============================================================================
// Habit Model - Represents a daily habit with streak tracking
// ============================================================================

class Habit {
  final String id;
  String name;
  String description;
  String emoji;
  int currentStreak;
  int longestStreak;
  List<DateTime> completedDates; // Dates when habit was completed
  List<int> scheduledDays; // 1 (Mon) to 7 (Sun)
  DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    this.description = '',
    this.emoji = '📚',
    this.currentStreak = 0,
    this.longestStreak = 0,
    List<DateTime>? completedDates,
    List<int>? scheduledDays,
    DateTime? createdAt,
  })  : completedDates = completedDates ?? [],
        scheduledDays = scheduledDays ?? [1, 2, 3, 4, 5, 6, 7],
        createdAt = createdAt ?? DateTime.now();

  // ── Check if habit is completed for a specific date ─────────────────
  bool isCompletedOn(DateTime date) {
    return completedDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  // ── Check if habit is scheduled for a specific date ─────────────────
  bool isScheduledFor(DateTime date) {
    return scheduledDays.contains(date.weekday);
  }

  // ── Check if completed today ────────────────────────────────────────
  bool get isCompletedToday => isCompletedOn(DateTime.now());

  // ── Database Serialization ──────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emoji': emoji,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedDates': completedDates.map((d) => d.millisecondsSinceEpoch).toList(),
      'scheduledDays': scheduledDays,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '📚',
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      completedDates: (map['completedDates'] as List<dynamic>?)
          ?.map((e) => DateTime.fromMillisecondsSinceEpoch(e as int))
          .toList() ?? [],
      scheduledDays: (map['scheduledDays'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [1, 2, 3, 4, 5, 6, 7],
    );
  }

  void toggleCompletion(DateTime date) {
    final existingIndex = completedDates.indexWhere(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );

    if (existingIndex >= 0) {
      completedDates.removeAt(existingIndex);
    } else {
      completedDates.add(date);
    }
  }
}
