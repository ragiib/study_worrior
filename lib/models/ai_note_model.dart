// ============================================================================
// AI Note Model - Represents a generated study note
// ============================================================================

enum NoteType {
  summary,
  detailed,
  bulletPoints,
  keyConcepts,
  definitions,
  formulas,
  examOriented,
  mcqs
}

class AiNote {
  final String id;
  String title;
  String content;
  NoteType type;
  DateTime createdAt;

  AiNote({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ── Database Serialization ──────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AiNote.fromMap(Map<String, dynamic> map) {
    return AiNote(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      type: NoteType.values[map['type'] as int],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  // Type label for display
  String get typeLabel {
    switch (type) {
      case NoteType.summary: return 'Summary';
      case NoteType.detailed: return 'Detailed Notes';
      case NoteType.bulletPoints: return 'Bullet Points';
      case NoteType.keyConcepts: return 'Key Concepts';
      case NoteType.definitions: return 'Definitions';
      case NoteType.formulas: return 'Formulas';
      case NoteType.examOriented: return 'Exam Prep';
      case NoteType.mcqs: return 'MCQs';
    }
  }

  AiNote copyWith({
    String? title,
    String? content,
    NoteType? type,
  }) {
    return AiNote(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt,
    );
  }
}
