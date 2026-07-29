import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'ai_model_manager.dart';

import '../../models/ai_note_model.dart';
import '../../models/chat_message.dart';
import 'ai_provider.dart';
import 'prompt_manager.dart';

class LocalLlamaAiProvider implements AiProvider {
  LlamaParent? _llamaParent;
  String? _currentModelPath;
  bool _isInitializing = false;

  final AiModelManager _modelManager;

  LocalLlamaAiProvider(this._modelManager) {
    _ensureInitialized().catchError((e) => debugPrint('[LocalLlamaAiProvider] early init failed: $e'));
  }

  Future<void> _ensureInitialized() async {
    if (_llamaParent != null) return;
    if (_isInitializing) {
      // Wait for initialization to finish if another call triggered it.
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_llamaParent != null) return;
    }

    _isInitializing = true;
    try {
      // Wait for the async constructor check to finish so modelPath is populated.
      await _modelManager.ready;

      final path = _modelManager.modelPath;

      if (path == null || path.isEmpty || !_modelManager.isDownloaded) {
        throw Exception('Offline AI model not ready. Please download the model first.');
      }

      // --- Pre-flight: verify the file actually exists and is complete ---
      final modelFile = File(path);
      final fileExists = await modelFile.exists();
      final fileSize = fileExists ? await modelFile.length() : 0;
      debugPrint('[LocalLlamaAiProvider] model path : $path');
      debugPrint('[LocalLlamaAiProvider] file exists: $fileExists');
      debugPrint('[LocalLlamaAiProvider] file size  : $fileSize bytes');

      if (!fileExists) {
        throw Exception(
          'Model file not found on disk at: $path\n'
          'Please delete and re-download the model from Settings.',
        );
      }
      if (fileSize < _modelManager.activeModelConfig.minBytes) {
        throw Exception(
          'Model file is incomplete ($fileSize bytes). '
          'Please delete and re-download the model from Settings.',
        );
      }

      _currentModelPath = path;

      final modelParams = ModelParams();
      // Use CPU-only inference (nGpuLayers = 0) so the model works on both
      // the Android emulator (no GPU) and physical devices. The 0.5B model
      // is small enough for CPU inference in reasonable time.
      modelParams.nGpuLayers = 0;
      modelParams.mainGpu = -1; // -1 bypasses the GPU device check when 0 devices are available

      final loadCommand = LlamaLoad(
        path: path,
        modelParams: modelParams,
        contextParams: ContextParams()
          ..nCtx = 2048
          ..nThreads = 4
          ..nThreadsBatch = 4,
        samplingParams: SamplerParams()..temp = 0.2,
        verbose: true, // Enable verbose native logging for diagnosis
      );

      debugPrint('[LocalLlamaAiProvider] calling LlamaParent.init() ...');
      _llamaParent = LlamaParent(loadCommand, ChatMLFormat());
      await _llamaParent!.init();
      debugPrint('[LocalLlamaAiProvider] initialization successful');
    } catch (e) {
      debugPrint('[LocalLlamaAiProvider] initialization failed: $e');
      _llamaParent = null; // ensure we retry on next call
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('alloc') || errorString.contains('memory') || errorString.contains('oom')) {
        throw Exception('Not enough memory to load this AI model. Please go to Settings and switch to a lighter model (e.g. 4GB tier).');
      }
      throw Exception('Failed to load AI model: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<String> _generateResponse(String prompt) async {
    await _ensureInitialized();
    final parent = _llamaParent!;

    // Completely clear the previous context and KV cache
    // so features like Note Generator and Doubt Solver do not mix state.
    await parent.clear();

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
    List<ChatMessage> history = const [],
  }) async {
    final prompt = PromptManager.getVoiceTeacherPrompt(question, history);
    return _generateResponse(prompt);
  }
}
