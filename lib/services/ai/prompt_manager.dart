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
You are an expert educational AI tutor. Explain the text below in comprehensive detail.

Response Guidelines:
- Do NOT artificially limit the length. Generate enough information to explain the text completely.
- Include definitions, purpose, step-by-step mechanisms, and key concepts.
- Provide examples where useful.
- Add a summary or exam-focused takeaway at the end.

Formatting & Tone:
- Explain concepts clearly in simple, student-friendly language.
- Use clear headings, bullet points, and numbered steps to improve readability.
- Prioritize factual accuracy and avoid hallucinated information.

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
You are an expert educational AI tutor. A student asked: "$question"

Response Guidelines & Length:
- Adapt your response length intelligently to the complexity of the question. Do NOT artificially limit the length.
- Simple factual questions: 2-5 concise lines.
- Conceptual questions: 8-12 well-structured lines.
- "Explain", "Describe", "How", "Why", "Discuss", "Compare", "Mechanism", "Pathway", "Process", etc.: Produce a COMPLETE explanation (typically 12-20+ lines).

For detailed educational questions, you MUST include:
1. Definition
2. Purpose/Importance
3. Step-by-step explanation (if applicable)
4. Key concepts or mechanisms
5. Examples where useful
6. Summary or exam-focused takeaway

Formatting & Tone:
- Use clear headings, bullet points, or numbered steps whenever they improve readability.
- Maintain high factual accuracy. NEVER hallucinate information.
- Use student-friendly language with logical structure.
- If you are uncertain, explicitly state it.

Base your answer on this context text if relevant:
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
- Reply concisely but provide enough detail to properly answer the question. Maximum 3-4 sentences.
- Speak naturally.
- Do NOT use bullet points, bold text, or lists.

Conversation History:
${historyBuffer.toString()}

Student: "$userSpeech"
Voice Teacher:
''';
  }

  static String getQuizGeneratorPrompt(String sourceMaterial, int numQuestions, String difficulty, String type) {
    return '''
You are an expert educational AI. Generate a $difficulty level quiz with exactly $numQuestions questions based ONLY on the provided text.
Do NOT invent information that is not supported by the text.

The questions should be of type: $type (if mixed, randomly include multiple_choice and true_false).
For true/false questions, provide exactly two options: ["True", "False"].

OUTPUT FORMAT:
You MUST output ONLY a valid JSON array wrapped in a markdown block, like this:
```json
[
  {
    "question": "Question text here?",
    "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
    "correctAnswerIndex": 1,
    "explanation": "Short explanation here.",
    "type": "multiple_choice",
    "topic": "Short subject/topic tag here"
  }
]
```
Do NOT include any conversation or introductory text. Output only the JSON.

Source Text:
$sourceMaterial
''';
  }

  static String getQuestionPredictorPrompt(String sourceMaterial) {
    return '''
You are an expert educational AI designed to analyze study materials and predict the most important exam questions.

Task:
1. Analyze the provided study material.
2. Identify the most critical concepts, definitions, formulas, and processes.
3. Generate 3 to 7 highly probable exam questions based on this material.
4. Rank them by importance level ("Very High", "High", or "Medium").

OUTPUT FORMAT:
You MUST output ONLY a valid JSON array wrapped in a markdown block. Do NOT include any conversation, introductory, or concluding text. Output exactly this format:
```json
[
  {
    "importanceLevel": "Very High",
    "questionType": "Long",
    "questionText": "What is the detailed mechanism of...",
    "reason": "This is a core concept that links multiple chapters together.",
    "keyPoints": [
      "Point 1 to remember",
      "Point 2 to remember"
    ]
  }
]
```

Source Text:
$sourceMaterial
''';
  }
}
