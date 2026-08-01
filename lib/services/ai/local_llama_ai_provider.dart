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
    // If we have an initialized model, check if the desired model has changed.
    if (_llamaParent != null) {
      if (_currentModelPath == _modelManager.modelPath) {
        return; // Already initialized with the correct model
      } else {
        // The user switched models! Dispose the old one.
        debugPrint('[LocalLlamaAiProvider] Model changed! Unloading old model...');
        _llamaParent!.dispose();
        _llamaParent = null;
        _currentModelPath = null;
      }
    }
    
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

  Future<String> _generateResponse(String prompt, {bool clearCache = true}) async {
    await _ensureInitialized();
    final parent = _llamaParent!;

    // Only clear the context if explicitly requested.
    // Voice Teacher maintains conversation history, so we don't clear it.
    if (clearCache) {
      debugPrint('[LocalLlamaAiProvider] Requesting Context Cleanup (clearCache=true)...');
      await parent.clear();
      debugPrint('[LocalLlamaAiProvider] Context Cleanup Completed.');
    }

    final buffer = StringBuffer();
    
    // Subscribe to stream
    final sub = parent.stream.listen((chunk) {
      buffer.write(chunk);
    });

    try {
      debugPrint('[LocalLlamaAiProvider] Inference: Sending prompt to model...');
      final promptId = await parent.sendPrompt(prompt);
      await parent.waitForCompletion(promptId);
      debugPrint('[LocalLlamaAiProvider] Inference: Generation completed successfully.');
      return buffer.toString().trim();
    } catch (e) {
      debugPrint('[LocalLlamaAiProvider] Inference Exceptions: $e');
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
    // Do not clear the cache for Voice Teacher to allow fast history processing
    return _generateResponse(prompt, clearCache: false);
  }

  @override
  Stream<String> askVoiceTeacherStream({
    required String question,
    List<ChatMessage> history = const [],
  }) async* {
    await _ensureInitialized();
    final parent = _llamaParent!;
    
    // Do not clear the cache for Voice Teacher to allow fast history processing
    // await parent.clear(); 
    
    final prompt = PromptManager.getVoiceTeacherPrompt(question, history);
    
    // Subscribe to stream BEFORE sending prompt to avoid missing tokens
    final controller = StreamController<String>();
    final sub = parent.stream.listen((chunk) {
      controller.add(chunk);
    });
    
    // Send prompt and yield stream
    try {
      debugPrint('[LocalLlamaAiProvider] Inference (Stream): Sending prompt to model...');
      final promptId = await parent.sendPrompt(prompt);
      
      // Await completion in background
      parent.waitForCompletion(promptId).then((_) {
        debugPrint('[LocalLlamaAiProvider] Inference (Stream): Generation completed successfully.');
        sub.cancel();
        controller.close();
      }).catchError((e) {
        debugPrint('[LocalLlamaAiProvider] Inference (Stream) Exceptions: $e');
        sub.cancel();
        controller.addError(e);
        controller.close();
      });
      
      yield* controller.stream;
      
    } catch (e) {
      debugPrint('[LocalLlamaAiProvider] Inference (Stream) Setup Exceptions: $e');
      sub.cancel();
      controller.close();
      rethrow;
    }
  }

  @override
  Future<String> generateQuiz({
    required String sourceMaterial,
    required int numQuestions,
    required String difficulty,
    required String type,
  }) async {
    final prompt = PromptManager.getQuizGeneratorPrompt(sourceMaterial, numQuestions, difficulty, type);
    final response = await _generateResponse(prompt);
    
    // Attempt to extract JSON from the response. Local models might include conversational fluff.
    // We look for ```json [content] ```
    final RegExp jsonRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final match = jsonRegex.firstMatch(response);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!.trim();
    }
    
    // Fallback: if no markdown block, maybe the whole response is just JSON array
    if (response.trim().startsWith('[') && response.trim().endsWith(']')) {
      return response.trim();
    }

    // If we failed to find JSON, throw an error with the raw response to help debugging
    throw Exception("AI generated invalid quiz format. Raw response: \$response");
  }
}
