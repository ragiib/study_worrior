class PredictedQuestion {
  final String importanceLevel; // Very High, High, Medium
  final String questionType;    // MCQ, Short, Long, Numerical, Diagram, Programming, etc.
  final String questionText;
  final String reason;          // Why this question is important
  final List<String> keyPoints; // Key revision points

  PredictedQuestion({
    required this.importanceLevel,
    required this.questionType,
    required this.questionText,
    required this.reason,
    required this.keyPoints,
  });

  factory PredictedQuestion.fromJson(Map<String, dynamic> json) {
    return PredictedQuestion(
      importanceLevel: json['importanceLevel'] as String? ?? 'Medium',
      questionType: json['questionType'] as String? ?? 'General',
      questionText: json['questionText'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      keyPoints: (json['keyPoints'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'importanceLevel': importanceLevel,
      'questionType': questionType,
      'questionText': questionText,
      'reason': reason,
      'keyPoints': keyPoints,
    };
  }
}
