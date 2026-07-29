import '../../models/ai_note_model.dart';
import '../../models/chat_message.dart';
import 'package:flutter/foundation.dart';

class PromptManager {
  /// Returns the appropriate prompt for the given [NoteType] and [text].
  static String getPrompt(NoteType type, String text) {
    debugPrint('PromptManager: Selecting template for NoteType.${type.name}');
    
    switch (type) {
      case NoteType.summary:
        return _getSummaryPrompt(text);
      case NoteType.detailed:
        return _getDetailedPrompt(text);
      case NoteType.bulletPoints:
        return _getRevisionPrompt(text);
      case NoteType.keyConcepts:
        return _getKeyConceptsPrompt(text);
      case NoteType.definitions:
        return _getDefinitionsPrompt(text);
      case NoteType.formulas:
        return _getFormulasPrompt(text);
      case NoteType.examOriented:
        return _getExamOrientedPrompt(text);
      case NoteType.mcqs:
        return _getMcqsPrompt(text);
      default:
        // Handle unsupported note types gracefully by falling back to detailed notes
        debugPrint('PromptManager: Unsupported note type, falling back to Detailed template.');
        return _getDetailedPrompt(text);
    }
  }

  static String _getSummaryPrompt(String text) {
    return '''
You are a tutor. Write a VERY short, simple summary of the text below.
Rules:
- Maximum 3 short sentences.
- Use words a 10-year-old understands.
- Be extremely brief.

Text:
$text
''';
  }

  static String _getDetailedPrompt(String text) {
    return '''
You are a tutor. Explain the text below simply.
Rules:
- Keep it under 150 words.
- Use short bullet points.
- Use simple, everyday language.

Text:
$text
''';
  }

  static String _getRevisionPrompt(String text) {
    return '''
You are a tutor. Extract the top 3 most important facts from the text below for an exam.
Rules:
- Exactly 3 short bullet points.
- No filler words.

Text:
$text
''';
  }

  static String _getKeyConceptsPrompt(String text) {
    return '''
You are a tutor. Identify the main concepts from the text below.
Rules:
- List a maximum of 3 concepts.
- Explain each in 1 short sentence.
- Very simple words.

Text:
$text
''';
  }

  static String _getDefinitionsPrompt(String text) {
    return '''
You are a tutor. Extract key words from the text below and define them.
Rules:
- Maximum 3 definitions.
- Keep definitions to 1 sentence each.
- Very simple words.

Text:
$text
''';
  }

  static String _getFormulasPrompt(String text) {
    return '''
You are a tutor. Find formulas or math/science equations in the text below.
Rules:
- If none exist, say "No formulas found."
- Keep explanations under 10 words per formula.

Text:
$text
''';
  }

  static String _getExamOrientedPrompt(String text) {
    return '''
You are a tutor preparing a student for an exam.
Rules:
- Give 2 short bullet points on what to study from the text below.
- Give 1 likely exam question.
- Keep it extremely brief.

Text:
$text
''';
  }

  static String _getMcqsPrompt(String text) {
    return '''
You are a tutor. Create exactly 3 simple Multiple Choice Questions based on the text below.
Rules:
- Provide the correct answer immediately after each question.
- Very short sentences.

Text:
$text
''';
  }

  static String getDoubtSolverPrompt(String text, String question) {
    return '''
You are a friendly tutor. A student asked: "$question"

Rules:
- Answer in 1 or 2 short, simple sentences.
- Use words a 10-year-old can understand.
- Be extremely brief. Do not ramble.
- Base your answer on this text:
$text
''';
  }

  static String getVoiceTeacherPrompt(String userSpeech, List<ChatMessage> history) {
    // Only take the last 6 messages (3 turns) to prevent context overflow
    final recentHistory = history.length > 6 ? history.sublist(history.length - 6) : history;
    
    final historyBuffer = StringBuffer();
    for (final msg in recentHistory) {
      if (msg.role == 'user') {
        historyBuffer.writeln('Student: "${msg.content}"');
      } else {
        historyBuffer.writeln('Voice Teacher: "${msg.content}"');
      }
    }

    return '''
You are an expert educational Voice Teacher. You are having a conversation with a student.
Rules:
- PRIORITIZE FACTUAL ACCURACY. If the student states a false premise (e.g. breathing on Jupiter without oxygen), you MUST politely correct them.
- Do NOT blindly agree with the student if they are incorrect.
- If you don't know the answer, say "I'm not sure about that." Do NOT guess or invent facts.
- Give simple, student-friendly explanations appropriate for a 10-year-old.
- Reply in exactly 1 or 2 short sentences.
- Speak naturally.
- Do NOT use bullet points, bold text, or lists.
- Be extremely brief.

Conversation History:
${historyBuffer.toString()}

Student: "$userSpeech"
Voice Teacher:
''';
  }
}
