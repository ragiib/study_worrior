// ============================================================================
// Habit Model - Represents a daily habit with streak tracking
// ============================================================================

class Habit {
  final String id;
  String name;
  String emoji;
  int currentStreak;
  int longestStreak;
  List<DateTime> completedDates; // Dates when habit was completed
  DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    this.emoji = '📚',
    this.currentStreak = 0,
    this.longestStreak = 0,
    List<DateTime>? completedDates,
    DateTime? createdAt,
  })  : completedDates = completedDates ?? [],
        createdAt = createdAt ?? DateTime.now();

  // ── Check if habit is completed for a specific date ─────────────────
  bool isCompletedOn(DateTime date) {
    return completedDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  // ── Check if completed today ────────────────────────────────────────
  bool get isCompletedToday => isCompletedOn(DateTime.now());

  // ── Database Serialization ──────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedDates': completedDates.map((d) => d.millisecondsSinceEpoch).toList(),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String? ?? '📚',
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      completedDates: (map['completedDates'] as List<dynamic>?)
          ?.map((e) => DateTime.fromMillisecondsSinceEpoch(e as int))
          .toList() ?? [],
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
