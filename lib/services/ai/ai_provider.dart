import '../../models/ai_note_model.dart';

import '../../models/chat_message.dart';

abstract class AiProvider {
  Future<String> generateNotes({
    required String extractedText,
    required NoteType type,
  });

  Future<String> answerDoubt({
    required String contextText,
    required String question,
  });

  Future<String> askVoiceTeacher({
    required String question,
    List<ChatMessage> history = const [],
  });

  Stream<String> askVoiceTeacherStream({
    required String question,
    List<ChatMessage> history = const [],
  });

  Future<String> generateQuiz({
    required String sourceMaterial,
    required int numQuestions,
    required String difficulty,
    required String type,
  });

  Future<String> predictImportantQuestions({
    required String sourceMaterial,
  });
}
