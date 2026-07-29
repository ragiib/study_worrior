import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AiModelManager extends ChangeNotifier {
  // Use Qwen 2.5 0.5B Instruct for fast mobile testing.
  // When Qwen 3 is available in GGUF format, update this URL.
  static const String modelUrl = 'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf';
  static const String modelFileName = 'qwen2.5-0.5b-instruct-q4_k_m.gguf';
  // Minimum expected file size (bytes). The full Q4_K_M is ~398 MB.
  static const int minModelBytes = 350 * 1024 * 1024;

  bool _isDownloaded = false;
  bool get isDownloaded => _isDownloaded;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  String? _modelPath;
  String? get modelPath => _modelPath;

  CancelToken? _cancelToken;

  // Completer that resolves once the initial model-existence check finishes.
  // Callers should `await manager.ready` before reading modelPath / isDownloaded
  // to avoid a race with the async constructor check.
  final Completer<void> _readyCompleter = Completer<void>();

  /// Resolves when the initial model-existence check on disk has completed.
  /// Always await this before reading [modelPath] or [isDownloaded].
  Future<void> get ready => _readyCompleter.future;

  AiModelManager() {
    _checkModelExists();
  }

  Future<void> _checkModelExists() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$modelFileName';
      final file = File(filePath);

      final exists = await file.exists();
      debugPrint('[AiModelManager] checking model: $filePath');
      debugPrint('[AiModelManager] file exists: $exists');

      if (exists) {
        final length = await file.length();
        debugPrint('[AiModelManager] file size: $length bytes');

        // Ensure the file is at least the minimum expected size.
        if (length > minModelBytes) {
          _isDownloaded = true;
          _modelPath = filePath;
          debugPrint('[AiModelManager] model ready at: $_modelPath');
          notifyListeners();
        } else {
          // Partial/corrupted download — remove it so the user can re-download.
          debugPrint('[AiModelManager] file too small ($length bytes), deleting.');
          await file.delete();
          _isDownloaded = false;
          _modelPath = null;
        }
      }

      // Also clean up any lingering temporary download files.
      final tempFile = File('$filePath.tmp');
      if (await tempFile.exists()) {
        debugPrint('[AiModelManager] removing stale .tmp file');
        await tempFile.delete();
      }
    } catch (e) {
      debugPrint('[AiModelManager] error checking model existence: $e');
    } finally {
      // Always complete the ready future so waiters are never stuck.
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    }
  }

  Future<void> downloadModel({required bool wifiOnly}) async {
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
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$modelFileName';
      final tempSavePath = '$savePath.tmp';
      
      final dio = Dio();
      _cancelToken = CancelToken();

      await dio.download(
        modelUrl,
        tempSavePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress = received / total;
            notifyListeners();
          }
        },
      );

      // Once download is fully complete, rename the temp file to the final model file name.
      final tempFile = File(tempSavePath);
      if (await tempFile.exists()) {
        await tempFile.rename(savePath);
      }

      final finalLength = await File(savePath).length();
      debugPrint('[AiModelManager] download complete. path: $savePath, size: $finalLength bytes');

      _isDownloaded = true;
      _modelPath = savePath;
      // Ensure ready completer is resolved for callers that awaited it before download.
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

  Future<void> deleteModel() async {
    try {
      if (_modelPath != null) {
        final file = File(_modelPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _isDownloaded = false;
      _modelPath = null;
      _downloadProgress = 0.0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting model: $e');
      throw Exception('Failed to delete model');
    }
  }
}
