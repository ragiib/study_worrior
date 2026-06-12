import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/ai_note_model.dart';
import 'ai_provider.dart';

class GeminiAiProvider implements AiProvider {
  static const String _apiKey = ApiConfig.geminiApiKey;
  // gemini-2.5-flash: Best free model — highest quality + generous free quota
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  @override
  Future<String> generateNotes({
    required String extractedText,
    required NoteType type,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception(
        'Gemini API key not configured. '
        'Open lib/config/api_config.dart and replace YOUR_API_KEY_HERE.',
      );
    }

    final prompt = _buildPrompt(extractedText, type);

    final response = await http.post(
      Uri.parse('$_baseUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 4096,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text != null) return text;
      throw Exception('Empty response from Gemini API.');
    } else {
      final error = jsonDecode(response.body);
      final message = error['error']?['message'] ?? 'Unknown API error';
      final status = response.statusCode;
      throw Exception('Gemini API error ($status): $message');
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
        typeInstruction =
            "Create exam-oriented study notes highlighting what to focus on, along with probable questions.";
        break;
      case NoteType.mcqs:
        typeInstruction =
            "Generate Multiple Choice Questions (MCQs) with the correct answers based on the text.";
        break;
    }

    return '''
You are an expert tutor and study assistant. Based on the following text extracted from a student's study materials, please generate notes.
Format your response entirely in Markdown. Do not include introductory conversational text.
Instruction: $typeInstruction

Extracted Text:
"""
$text
"""
''';
  }
}
