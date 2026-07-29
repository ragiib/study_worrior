import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/quiz_model.dart';
import '../../services/ai/ai_provider.dart';
import '../../services/ocr_service.dart';

class AiQuizProvider extends ChangeNotifier {
  final OcrService _ocrService = OcrService();
  AiProvider? _aiProvider;

  final List<XFile> _selectedImages = [];
  List<XFile> get selectedImages => _selectedImages;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String _processingStatus = '';
  String get processingStatus => _processingStatus;

  String? _lastError;
  String? get lastError => _lastError;

  void updateAiProvider(AiProvider aiProvider) {
    _aiProvider = aiProvider;
    notifyListeners();
  }

  Future<void> pickImages(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    
    if (source == ImageSource.gallery) {
      final List<XFile> images = await picker.pickMultiImage(imageQuality: 80);
      if (images.isNotEmpty) {
        _selectedImages.addAll(images);
        notifyListeners();
      }
    } else if (source == ImageSource.camera) {
      final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
      if (image != null) {
        _selectedImages.add(image);
        notifyListeners();
      }
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  void clearImages() {
    _selectedImages.clear();
    notifyListeners();
  }

  Future<Quiz?> generateQuiz({
    String? manualText,
    required int numQuestions,
    required String difficulty,
    required String type,
  }) async {
    if (_selectedImages.isEmpty && (manualText == null || manualText.trim().isEmpty)) {
      _lastError = "Please provide some text or select an image.";
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      String extractedText = manualText?.trim() ?? '';
      
      if (_selectedImages.isNotEmpty) {
        _processingStatus = 'Extracting text from images...';
        notifyListeners();
        
        final imagePaths = _selectedImages.map((e) => e.path).toList();
        final ocrText = await _ocrService.extractTextFromMultipleImages(imagePaths);
        
        if (extractedText.isNotEmpty) {
          extractedText += "\n\n" + ocrText;
        } else {
          extractedText = ocrText;
        }
      }

      if (extractedText.trim().isEmpty) {
        throw Exception("No text found. Please provide valid text or clearer images.");
      }

      _processingStatus = 'Generating quiz with AI...';
      notifyListeners();

      if (_aiProvider == null) {
        throw Exception("AI Engine is not initialized.");
      }

      final jsonString = await _aiProvider!.generateQuiz(
        sourceMaterial: extractedText,
        numQuestions: numQuestions,
        difficulty: difficulty,
        type: type,
      );

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final quiz = Quiz.fromJson(jsonList);

      if (quiz.questions.isEmpty) {
        throw Exception("AI failed to generate any questions.");
      }

      clearImages();
      return quiz;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      } else if (errorMessage.contains('FormatException')) {
        errorMessage = 'AI returned malformed data. Please try again.';
      }
      _lastError = errorMessage;
      debugPrint('AiQuizProvider Error: \$e');
      return null;
    } finally {
      _isProcessing = false;
      _processingStatus = '';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
