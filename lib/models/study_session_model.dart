// ============================================================================
// Study Session Model - Records study time for dashboard analytics
// ============================================================================

class StudySession {
  final String id;
  final int durationMinutes;
  final DateTime date;
  final String type; // 'pomodoro' or 'manual'

  StudySession({
    required this.id,
    required this.durationMinutes,
    required this.date,
    this.type = 'pomodoro',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'durationMinutes': durationMinutes,
      'date': date.millisecondsSinceEpoch,
      'type': type,
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] as String,
      durationMinutes: map['durationMinutes'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      type: map['type'] as String? ?? 'pomodoro',
    );
  }
}
