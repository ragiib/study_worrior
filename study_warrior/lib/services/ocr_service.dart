import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  TextRecognizer? _textRecognizer;

  OcrService() {
    _initializeRecognizer();
  }

  void _initializeRecognizer() {
    try {
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      }
    } catch (e) {
      debugPrint('OcrService: Failed to initialize TextRecognizer: $e');
    }
  }

  bool get isSupportedPlatform => 
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<String> extractTextFromImage(String imagePath) async {
    debugPrint('OcrService: Extracting text from image $imagePath');
    
    if (kIsWeb) {
      debugPrint('OcrService: Web platform detected. Simulating OCR.');
      await Future.delayed(const Duration(seconds: 1));
      return "Simulated OCR text for web. Google ML Kit is not supported on the web platform.";
    }

    if (!isSupportedPlatform) {
      debugPrint('OcrService: Unsupported platform detected.');
      throw Exception('OCR is only supported on Android and iOS devices.');
    }

    if (_textRecognizer == null) {
      throw Exception('OCR Recognizer failed to initialize.');
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      
      if (recognizedText.text.trim().isEmpty) {
        debugPrint('OcrService: No text found in image.');
        return '';
      }
      
      return recognizedText.text;
    } catch (e) {
      debugPrint('OcrService Error extracting text: $e');
      throw Exception('Failed to process image: $e');
    }
  }

  Future<String> extractTextFromMultipleImages(List<String> imagePaths) async {
    if (!kIsWeb && !isSupportedPlatform) {
      throw Exception('OCR_UNSUPPORTED: Image text extraction is only supported on Android and iOS devices.');
    }

    StringBuffer allText = StringBuffer();
    for (int i = 0; i < imagePaths.length; i++) {
      try {
        final text = await extractTextFromImage(imagePaths[i]);
        if (text.isNotEmpty) {
          allText.writeln('--- Page ${i + 1} ---');
          allText.writeln(text);
          allText.writeln();
        }
      } catch (e) {
        if (e.toString().contains('OCR_UNSUPPORTED')) {
          rethrow;
        }
        debugPrint('OcrService: Skipping page $i due to error: $e');
      }
    }
    
    final finalResult = allText.toString();
    if (finalResult.trim().isEmpty) {
      throw Exception('EMPTY_OCR: No readable text could be found in the selected images.');
    }
    
    return finalResult;
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
