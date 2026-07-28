import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'ai_model_manager.dart';

import '../../models/ai_note_model.dart';
import 'ai_provider.dart';
import 'prompt_manager.dart';

class LocalLlamaAiProvider implements AiProvider {
  LlamaParent? _llamaParent;
  String? _currentModelPath;
  bool _isInitializing = false;

  final AiModelManager _modelManager;

  LocalLlamaAiProvider(this._modelManager);

  Future<void> _ensureInitialized() async {
    if (_llamaParent != null) return;
    if (_isInitializing) {
      // Wait for initialization to finish if another call triggered it
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_llamaParent != null) return;
    }

    _isInitializing = true;
    try {
      final path = _modelManager.modelPath;

      if (path == null || path.isEmpty || !_modelManager.isDownloaded) {
        throw Exception('Offline AI model not ready. Please download the model first.');
      }

      _currentModelPath = path;

      debugPrint('LocalLlamaAiProvider: Initializing with model at $path');

      final loadCommand = LlamaLoad(
        path: path,
        modelParams: ModelParams(),
        contextParams: ContextParams()..nCtx = 2048,
        samplingParams: SamplerParams()..temp = 0.7,
      );

      _llamaParent = LlamaParent(loadCommand, ChatMLFormat());
      await _llamaParent!.init();
      debugPrint('LocalLlamaAiProvider: Initialization successful');
    } finally {
      _isInitializing = false;
    }
  }

  Future<String> _generateResponse(String prompt) async {
    await _ensureInitialized();
    final parent = _llamaParent!;

    final buffer = StringBuffer();
    
    // Subscribe to stream
    final sub = parent.stream.listen((chunk) {
      buffer.write(chunk);
    });

    try {
      final promptId = await parent.sendPrompt(prompt);
      await parent.waitForCompletion(promptId);
      return buffer.toString().trim();
    } catch (e) {
      debugPrint('LocalLlamaAiProvider Error: $e');
      rethrow;
    } finally {
      await sub.cancel();
    }
  }

  @override
  Future<String> generateNotes({
    required String extractedText,
    required NoteType type,
  }) async {
    final prompt = PromptManager.getPrompt(type, extractedText);
    return _generateResponse(prompt);
  }

  @override
  Future<String> answerDoubt({
    required String contextText,
    required String question,
  }) async {
    final prompt = PromptManager.getDoubtSolverPrompt(contextText, question);
    return _generateResponse(prompt);
  }

  @override
  Future<String> askVoiceTeacher({
    required String question,
  }) async {
    final prompt = PromptManager.getVoiceTeacherPrompt(question);
    return _generateResponse(prompt);
  }
}
