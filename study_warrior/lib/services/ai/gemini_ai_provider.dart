import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../models/ai_note_model.dart';
import 'ai_provider.dart';

class GeminiAiProvider implements AiProvider {
  late final GenerativeModel _model;

  GeminiAiProvider() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('GEMINI_API_KEY is not set in .env file. Please add your Gemini API Key.');
    }
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  @override
  Future<String> generateNotes({
    required String extractedText,
    required NoteType type,
  }) async {
    final prompt = _buildPrompt(extractedText, type);
    
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No content generated.';
    } catch (e) {
      throw Exception('Failed to generate notes: $e');
    }
  }

  String _buildPrompt(String text, NoteType type) {
    String typeInstruction;
    switch (type) {
      case NoteType.summary:
        typeInstruction = "Provide a concise summary.";
        break;
      case NoteType.detailed:
        typeInstruction = "Provide detailed, comprehensive notes.";
        break;
      case NoteType.bulletPoints:
        typeInstruction = "Provide revision notes in bullet points.";
        break;
      case NoteType.keyConcepts:
        typeInstruction = "Extract and explain the key concepts.";
        break;
      case NoteType.definitions:
        typeInstruction = "Extract and list important definitions.";
        break;
      case NoteType.formulas:
        typeInstruction = "Extract any formulas or equations and explain them.";
        break;
      case NoteType.examOriented:
        typeInstruction = "Create exam-oriented study notes highlighting what to focus on, along with probable questions.";
        break;
      case NoteType.mcqs:
        typeInstruction = "Generate Multiple Choice Questions (MCQs) with the correct answers based on the text.";
        break;
    }

    return '''
You are an expert tutor and study assistant. Based on the following text extracted from a student's study materials, please generate notes.
Format your response entirely in Markdown. Do not include introductory conversational text.
Instruction: \$typeInstruction

Extracted Text:
"""
\$text
"""
''';
  }
}
