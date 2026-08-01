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
      // Hardcode CPU-only inference to prevent native GPU SIGSEGV crashes on Android
      modelParams.nGpuLayers = 0;
      modelParams.mainGpu = -1;

      final config = _modelManager.activeModelConfig;
      
      final loadCommand = LlamaLoad(
        path: path,
        modelParams: modelParams,
        contextParams: ContextParams()
          ..nCtx = config.contextSize
          ..nThreads = 8
          ..nThreadsBatch = 8,
        samplingParams: SamplerParams()
          ..temp = config.temperature
          ..topP = config.topP
          ..topK = config.topK
          ..penaltyRepeat = config.repetitionPenalty,
        verbose: true, // Enable verbose native logging for diagnosis
      );

      debugPrint('[LocalLlamaAiProvider] calling LlamaParent.init() on CPU...');
      _llamaParent = LlamaParent(loadCommand, ChatMLFormat());
      await _llamaParent!.init();
      debugPrint('[LocalLlamaAiProvider] initialization on CPU successful');
    } catch (e) {
      debugPrint('[LocalLlamaAiProvider] initialization failed: $e');
      _llamaParent?.dispose();
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
    final swTotal = Stopwatch()..start();

    if (clearCache) {
      debugPrint('[LocalLlamaAiProvider] Requesting Context Cleanup (clearCache=true)...');
      final swClear = Stopwatch()..start();
      await parent.clear();
      debugPrint('[LocalLlamaAiProvider] Context Cleanup Completed in ${swClear.elapsedMilliseconds} ms.');
    }

    final buffer = StringBuffer();
    
    final sub = parent.stream.listen((chunk) {
      buffer.write(chunk);
    });

    try {
      debugPrint('[LocalLlamaAiProvider] Inference: Sending prompt to model...');
      final swPrompt = Stopwatch()..start();
      final promptId = await parent.sendPrompt(prompt);
      debugPrint('[LocalLlamaAiProvider] Inference: sendPrompt completed in ${swPrompt.elapsedMilliseconds} ms. Waiting for completion...');
      
      final swWait = Stopwatch()..start();
      await parent.waitForCompletion(promptId);
      debugPrint('[LocalLlamaAiProvider] Inference: Generation completed successfully in ${swWait.elapsedMilliseconds} ms. Total time: ${swTotal.elapsedMilliseconds} ms.');
      return buffer.toString().trim();
    } catch (e) {
      debugPrint('[LocalLlamaAiProvider] Inference Exceptions after ${swTotal.elapsedMilliseconds} ms: $e');
      rethrow;
    } finally {
      await sub.cancel();
      debugPrint('[LocalLlamaAiProvider] Inference Stream subscription cancelled.');
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
    
    final prompt = PromptManager.getVoiceTeacherPrompt(question, history);
    
    final controller = StreamController<String>();
    bool isFirstToken = true;
    final swTotal = Stopwatch()..start();
    final swPrompt = Stopwatch();
    
    final sub = parent.stream.listen((chunk) {
      if (isFirstToken) {
         debugPrint('[LocalLlamaAiProvider] VoiceTeacher: First token received at ${swTotal.elapsedMilliseconds} ms.');
         isFirstToken = false;
      }
      controller.add(chunk);
    });
    
    try {
      debugPrint('[LocalLlamaAiProvider] VoiceTeacher: Sending prompt to model...');
      swPrompt.start();
      final promptId = await parent.sendPrompt(prompt);
      debugPrint('[LocalLlamaAiProvider] VoiceTeacher: sendPrompt finished in ${swPrompt.elapsedMilliseconds} ms.');
      
      parent.waitForCompletion(promptId).then((_) {
        debugPrint('[LocalLlamaAiProvider] VoiceTeacher: Generation completed successfully in ${swTotal.elapsedMilliseconds} ms.');
        sub.cancel();
        controller.close();
      }).catchError((e) {
        debugPrint('[LocalLlamaAiProvider] VoiceTeacher: Exceptions during stream generation after ${swTotal.elapsedMilliseconds} ms: $e');
        sub.cancel();
        controller.addError(e);
        controller.close();
      });
      
      yield* controller.stream;
      
    } catch (e) {
      debugPrint('[LocalLlamaAiProvider] VoiceTeacher: Setup Exceptions: $e');
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
