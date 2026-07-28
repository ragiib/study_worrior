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

  bool _isDownloaded = false;
  bool get isDownloaded => _isDownloaded;

  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  String? _modelPath;
  String? get modelPath => _modelPath;

  CancelToken? _cancelToken;

  AiModelManager() {
    _checkModelExists();
  }

  Future<void> _checkModelExists() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$modelFileName');
      if (await file.exists()) {
        final length = await file.length();
        if (length > 0) {
          _isDownloaded = true;
          _modelPath = file.path;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error checking model existence: $e');
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
      
      final dio = Dio();
      _cancelToken = CancelToken();

      await dio.download(
        modelUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress = received / total;
            notifyListeners();
          }
        },
      );

      _isDownloaded = true;
      _modelPath = savePath;
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
