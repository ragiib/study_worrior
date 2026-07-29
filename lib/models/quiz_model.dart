class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final String type; // 'multiple_choice', 'true_false'

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.type,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
      type: json['type'] ?? 'multiple_choice',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'type': type,
    };
  }
}

class Quiz {
  final List<QuizQuestion> questions;

  Quiz({required this.questions});

  factory Quiz.fromJson(List<dynamic> jsonList) {
    return Quiz(
      questions: jsonList.map((e) => QuizQuestion.fromJson(e)).toList(),
    );
  }
}

class QuizResult {
  final Quiz quiz;
  final Map<int, int> userAnswers; // questionIndex -> selectedOptionIndex

  QuizResult({
    required this.quiz,
    required this.userAnswers,
  });

  int get score {
    int s = 0;
    for (int i = 0; i < quiz.questions.length; i++) {
      if (userAnswers[i] == quiz.questions[i].correctAnswerIndex) {
        s++;
      }
    }
    return s;
  }
  
  double get percentage => quiz.questions.isEmpty ? 0 : (score / quiz.questions.length) * 100;
}
