import '../../models/ai_note_model.dart';

abstract class AiProvider {
  Future<String> generateNotes({
    required String extractedText,
    required NoteType type,
  });
}
