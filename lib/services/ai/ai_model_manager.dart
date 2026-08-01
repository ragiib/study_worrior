import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiModelTier {
  tier4GB,
  tier6GB,
  tier8GB,
}

class AiModelConfig {
  final AiModelTier tier;
  final String name;
  final String description;
  final String url;
  final String filename;
  final int minBytes;
  final int requiredRamGB;
  final String displaySize;
  final int contextSize;
  final double temperature;
  final double topP;
  final int topK;
  final double repetitionPenalty;

  const AiModelConfig({
    required this.tier,
    required this.name,
    required this.description,
    required this.url,
    required this.filename,
    required this.minBytes,
    required this.requiredRamGB,
    required this.displaySize,
    required this.contextSize,
    required this.temperature,
    required this.topP,
    required this.topK,
    required this.repetitionPenalty,
  });
}

class AiModelManager extends ChangeNotifier {
  static const String _prefKeySelectedTier = 'ai_model_selected_tier';

  static const Map<AiModelTier, AiModelConfig> availableModels = {
    AiModelTier.tier4GB: AiModelConfig(
      tier: AiModelTier.tier4GB,
      name: 'Qwen 2.5 (0.5B Instruct)',
      description: 'Lightweight model. Fast and uses very little RAM.',
      url: 'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
      filename: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
      minBytes: 350 * 1024 * 1024,
      requiredRamGB: 4,
      displaySize: '~398 MB',
      contextSize: 2048,
      temperature: 0.3,
      topP: 0.85,
      topK: 40,
      repetitionPenalty: 1.1,
    ),
    AiModelTier.tier6GB: AiModelConfig(
      tier: AiModelTier.tier6GB,
      name: 'Qwen 2.5 (3B Instruct)',
      description: 'Balanced model. Better reasoning, requires more RAM.',
      url: 'https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf',
      filename: 'qwen2.5-3b-instruct-q4_k_m.gguf',
      minBytes: 1500 * 1024 * 1024,
      requiredRamGB: 6,
      displaySize: '~2.0 GB',
      contextSize: 4096,
      temperature: 0.5,
      topP: 0.9,
      topK: 50,
      repetitionPenalty: 1.05,
    ),
    AiModelTier.tier8GB: AiModelConfig(
      tier: AiModelTier.tier8GB,
      name: 'Qwen 2.5 (7B Instruct)',
      description: 'Heavyweight model. Best reasoning, requires 8GB+ RAM.',
      url: 'https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/main/qwen2.5-7b-instruct-q4_k_m.gguf',
      filename: 'qwen2.5-7b-instruct-q4_k_m.gguf',
      minBytes: 4000 * 1024 * 1024,
      requiredRamGB: 8,
      displaySize: '~4.3 GB',
      contextSize: 4096,
      temperature: 0.6,
      topP: 0.9,
      topK: 50,
      repetitionPenalty: 1.05,
    ),
  };

  bool _isDownloaded = false;
  bool get isDownloaded => _isDownloaded;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  String? _modelPath;
  String? get modelPath => _modelPath;

  AiModelTier _selectedTier = AiModelTier.tier4GB;
  AiModelTier get selectedTier => _selectedTier;

  AiModelConfig get activeModelConfig => availableModels[_selectedTier]!;

  CancelToken? _cancelToken;

  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  AiModelManager() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTierIndex = prefs.getInt(_prefKeySelectedTier);
    if (savedTierIndex != null && savedTierIndex >= 0 && savedTierIndex < AiModelTier.values.length) {
      _selectedTier = AiModelTier.values[savedTierIndex];
    }
    await _checkModelExists();
  }

  Future<bool> doesModelExistLocally(AiModelTier tier) async {
    try {
      final config = availableModels[tier]!;
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${config.filename}';
      final file = File(filePath);

      if (await file.exists()) {
        final length = await file.length();
        if (length > config.minBytes) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> switchActiveModel(AiModelTier newTier) async {
    if (await doesModelExistLocally(newTier)) {
      _selectedTier = newTier;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeySelectedTier, newTier.index);
      await _checkModelExists();
    } else {
      throw Exception('Cannot switch to a model that is not downloaded.');
    }
  }

  Future<void> _checkModelExists() async {
    try {
      final config = activeModelConfig;
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${config.filename}';
      final file = File(filePath);

      final exists = await file.exists();
      
      if (exists) {
        final length = await file.length();
        if (length > config.minBytes) {
          // Verify the file is actually readable (not corrupted OS lock or missing permissions)
          try {
            await file.openRead().first;
            _isDownloaded = true;
            _modelPath = filePath;
          } catch (e) {
            debugPrint('[AiModelManager] Model file exists but is not readable: $e');
            _isDownloaded = false;
            _modelPath = null;
          }
          notifyListeners();
        } else {
          await file.delete();
          _isDownloaded = false;
          _modelPath = null;
        }
      } else {
        _isDownloaded = false;
        _modelPath = null;
      }

      final tempFile = File('$filePath.tmp');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      debugPrint('[AiModelManager] error checking model existence: $e');
    } finally {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    }
  }

  /// Permanently deletes the currently selected model from disk
  /// and updates the internal state. Useful if the model is corrupted.
  Future<void> deleteCurrentModel() async {
    try {
      final config = activeModelConfig;
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${config.filename}';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }
      
      _isDownloaded = false;
      _modelPath = null;
      notifyListeners();
      debugPrint('[AiModelManager] Successfully deleted current model: $filePath');
    } catch (e) {
      debugPrint('[AiModelManager] Error deleting model: $e');
    }
  }

  Future<void> downloadModel(AiModelTier tierToDownload, {required bool wifiOnly}) async {
    if (_isDownloading) return;

    if (wifiOnly) {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (!connectivityResult.contains(ConnectivityResult.wifi)) {
        throw Exception('WiFi is required to download the model, but you are not connected to WiFi.');
      }
    }

    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();

    try {
      final config = availableModels[tierToDownload]!;
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${config.filename}';
      final tempSavePath = '$savePath.tmp';
      
      final dio = Dio();
      _cancelToken = CancelToken();

      await dio.download(
        config.url,
        tempSavePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress = received / total;
            notifyListeners();
          }
        },
      );

      final tempFile = File(tempSavePath);
      if (await tempFile.exists()) {
        await tempFile.rename(savePath);
      }

      _selectedTier = tierToDownload;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKeySelectedTier, tierToDownload.index);
      
      _isDownloaded = true;
      _modelPath = savePath;

      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    } catch (e) {
      debugPrint('Model download error: $e');
      if (e is DioException && CancelToken.isCancel(e)) {
        throw Exception('Download canceled');
      }
      throw Exception('Failed to download model: $e');
    } finally {
      _isDownloading = false;
      _cancelToken = null;
      notifyListeners();
    }
  }

  void cancelDownload() {
    if (_isDownloading && _cancelToken != null) {
      _cancelToken!.cancel('User canceled download');
    }
  }

  Future<void> deleteSpecificModel(AiModelTier tier) async {
    try {
      final config = availableModels[tier]!;
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${config.filename}';
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      if (_selectedTier == tier) {
        _isDownloaded = false;
        _modelPath = null;
        _downloadProgress = 0.0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting model $tier: $e');
      throw Exception('Failed to delete model');
    }
  }
}
