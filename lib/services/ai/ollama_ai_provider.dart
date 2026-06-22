import 'dart:convert';
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
    // Safe platform check that won't crash on web
    if (defaultTargetPlatform == TargetPlatform.android) {
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
        debugPrint('OllamaAiProvider: Request timed out');
        throw Exception('TIMEOUT: Request to Ollama timed out. Ensure the $_model model is downloaded and Ollama is running.');
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['response'];
        if (text != null) {
          debugPrint('OllamaAiProvider: Successfully generated notes');
          return text;
        }
        throw Exception('Empty response from Ollama API.');
      } else if (response.statusCode == 404) {
        throw Exception('OLLAMA_MODEL_NOT_FOUND: Model "$_model" not found. Please run "ollama run $_model" in your terminal first.');
      } else {
        final status = response.statusCode;
        throw Exception('OLLAMA_ERROR: API returned status $status - ${response.body}');
      }
    } catch (e) {
      debugPrint('OllamaAiProvider Exception: $e');
      final errorStr = e.toString();
      
      // Catch common web CORS and network errors
      if (kIsWeb && (errorStr.contains('XMLHttpRequest error') || errorStr.contains('Failed to fetch'))) {
        throw Exception(
          'CORS_ERROR: Your browser blocked the connection to Ollama.\n\n'
          'To fix this forever:\n'
          '1. Search for "Environment Variables" in Windows Start Menu.\n'
          '2. Add a new System Variable: Name=OLLAMA_ORIGINS Value=*\n'
          '3. Fully quit Ollama (right-click its icon in the system tray -> Quit) and start it again.'
        );
      }
      
      if (errorStr.contains('Connection refused') || errorStr.contains('Failed host lookup') || errorStr.contains('SocketException')) {
        throw Exception('CONNECTION_ERROR: Could not connect to Ollama at $_baseUrl. Please ensure Ollama is running locally.');
      }
      
      rethrow;
    }
  }
}
