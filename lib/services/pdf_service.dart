import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  Future<PlatformFile?> pickPdf() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      debugPrint('PdfService: Error picking PDF: $e');
      throw Exception('Failed to pick PDF file.');
    }
  }

  Future<String> extractTextFromPdf(String path) async {
    try {
      final File file = File(path);
      final List<int> bytes = await file.readAsBytes();
      
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();
      
      document.dispose();
      
      return text;
    } catch (e) {
      debugPrint('PdfService: Error extracting text from PDF: $e');
      throw Exception('Failed to extract text from the PDF. It might be corrupted, image-only, or password protected.');
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
