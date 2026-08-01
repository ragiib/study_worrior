import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/predicted_question.dart';
import '../../services/ai/ai_provider.dart';
import '../../services/ocr_service.dart';
import '../../services/pdf_service.dart';

class AiPredictorProvider extends ChangeNotifier {
  final OcrService _ocrService = OcrService();
  final PdfService _pdfService = PdfService();
  AiProvider? _aiProvider;

  final List<XFile> _selectedImages = [];
  List<XFile> get selectedImages => _selectedImages;

  PlatformFile? _selectedPdf;
  PlatformFile? get selectedPdf => _selectedPdf;

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

  Future<void> pickPdf() async {
    final pdf = await _pdfService.pickPdf();
    if (pdf != null) {
      _selectedPdf = pdf;
      notifyListeners();
    }
  }

  void removePdf() {
    _selectedPdf = null;
    notifyListeners();
  }

  String formatFileSize(int bytes) => _pdfService.formatFileSize(bytes);

  void clearImagesAndPdf() {
    _selectedImages.clear();
    _selectedPdf = null;
    notifyListeners();
  }

  Future<List<PredictedQuestion>?> predictQuestions({
    String? manualText,
  }) async {
    if (_selectedImages.isEmpty && _selectedPdf == null && (manualText == null || manualText.trim().isEmpty)) {
      _lastError = "Please provide some text, select an image, or upload a PDF.";
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _lastError = null;
    notifyListeners();

    try {
      String extractedText = manualText?.trim() ?? '';
      
      if (_selectedPdf != null) {
        _processingStatus = 'Extracting text from PDF...';
        notifyListeners();
        
        try {
          final pdfText = await _pdfService.extractTextFromPdf(_selectedPdf!.path!);
          if (extractedText.isNotEmpty) {
            extractedText += "\n\n" + pdfText;
          } else {
            extractedText = pdfText;
          }
        } catch (e) {
          debugPrint('[AiPredictorProvider] PDF Extraction Exceptions: $e');
          _lastError = e.toString().replaceAll('Exception: ', '');
          notifyListeners();
        }
      }

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

      _processingStatus = 'Predicting exam questions...';
      notifyListeners();

      if (_aiProvider == null) {
        throw Exception("AI Engine is not initialized.");
      }

      debugPrint('[AiPredictorProvider] Inference Start for Predictions...');
      final jsonString = await _aiProvider!.predictImportantQuestions(
        sourceMaterial: extractedText,
      ).timeout(
        const Duration(minutes: 4),
        onTimeout: () {
          debugPrint('[AiPredictorProvider] Inference timed out');
          throw Exception('AI generation took too long. Please try a shorter document.');
        },
      );
      
      debugPrint('[AiPredictorProvider] Predictions generated successfully.');

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<PredictedQuestion> questions = jsonList
          .map((item) => PredictedQuestion.fromJson(item as Map<String, dynamic>))
          .toList();

      if (questions.isEmpty) {
        throw Exception("AI failed to predict any questions.");
      }

      clearImagesAndPdf();
      return questions;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      } else if (errorMessage.contains('FormatException')) {
        errorMessage = 'AI returned malformed data. Please try again.';
      }
      _lastError = errorMessage;
      debugPrint('AiPredictorProvider Error: \$e');
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
