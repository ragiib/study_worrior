import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/ai_note_model.dart';
import 'ai_provider.dart';
import 'prompt_manager.dart';

class OllamaAiProvider implements AiProvider {
  // Use qwen or qwen:3b or qwen2.5 depending on what the user has pulled
  static const String _model = 'qwen';
  
  // Timeout for local generation
  static const Duration _timeout = Duration(minutes: 5);

  String get _baseUrl {
    if (kIsWeb) {
      // Use your PC's local IP address so smartphones can reach Ollama over Wi-Fi
      return 'http://10.255.96.164:11434/api/generate';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:11434/api/generate';
    }
    return 'http://127.0.0.1:11434/api/generate';
  }

  @override
  Future<String> generateNotes({
    required String extractedText,
    required NoteType type,
  }) async {
    final prompt = PromptManager.getPrompt(type, extractedText);
    
    debugPrint('OllamaAiProvider: Sending request to $_baseUrl with model $_model');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'prompt': prompt,
          'stream': false,
        }),
      ).timeout(_timeout, onTimeout: () {
        throw Exception('Request to Ollama timed out. Ensure Ollama is running and model $_model is pulled.');
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['response'];
        if (text != null) return text;
        throw Exception('Empty response from Ollama API.');
      } else {
        final status = response.statusCode;
        throw Exception('Ollama API error ($status): ${response.body}');
      }
    } catch (e) {
      debugPrint('OllamaAiProvider Exception: $e');
      if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        throw Exception('Could not connect to Ollama at $_baseUrl. Please ensure Ollama is running locally.');
      }
      rethrow;
    }
  }
}
