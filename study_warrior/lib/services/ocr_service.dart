import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
class OcrService {
  TextRecognizer? _textRecognizer;

  OcrService() {
    if (!kIsWeb) {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    }
  }

  Future<String> extractTextFromImage(String imagePath) async {
    if (kIsWeb) {
      // Simulate OCR on web because Google ML Kit is mobile only
      await Future.delayed(const Duration(seconds: 1));
      return "Simulated OCR text for web. Google ML Kit is not supported on the web platform.";
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print('Error extracting text: $e');
      return '';
    }
  }

  Future<String> extractTextFromMultipleImages(List<String> imagePaths) async {
    StringBuffer allText = StringBuffer();
    for (int i = 0; i < imagePaths.length; i++) {
      final text = await extractTextFromImage(imagePaths[i]);
      if (text.isNotEmpty) {
        allText.writeln('--- Page ${i + 1} ---');
        allText.writeln(text);
        allText.writeln();
      }
    }
    return allText.toString();
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
