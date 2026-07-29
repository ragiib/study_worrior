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
}
