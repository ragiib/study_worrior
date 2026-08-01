import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:file_picker/file_picker.dart';

import '../../models/ai_note_model.dart';
import '../../services/ai/ai_provider.dart';
import '../../services/ocr_service.dart';
import '../../services/pdf_service.dart';
import '../../services/database_service.dart';

class AiNotesProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  final OcrService _ocrService = OcrService();
  final PdfService _pdfService = PdfService();
  AiProvider? _aiProvider;
  final _uuid = const Uuid();

  List<AiNote> _notes = [];
  List<AiNote> get notes => _notes;

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

  AiNotesProvider(this._dbService) {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    if (!_dbService.isInitialized) {
      await _dbService.initialize();
    }
    _notes = await _dbService.getAllAiNotes();
    _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  Future<AiNote?> generateNotes(NoteType type, String title) async {
    if (_selectedImages.isEmpty && _selectedPdf == null) return null;

    _isProcessing = true;
    notifyListeners();

    try {
      String extractedText = '';

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
          debugPrint('[AiNotesProvider] PDF Extraction Exceptions: $e');
          _lastError = e.toString().replaceAll('Exception: ', '');
          notifyListeners();
          // Continue functioning normally for image extraction if available
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
        throw Exception("No text could be extracted from the provided files.");
      }

      _processingStatus = 'Generating ${type.name} notes using AI...';
      notifyListeners();

      if (_aiProvider == null) {
        throw Exception("AI Engine is not initialized.");
      }

      debugPrint('[AiNotesProvider] Context Creation & Inference Start for Notes...');
      final generatedContent = await _aiProvider!.generateNotes(
        extractedText: extractedText,
        type: type,
      ).timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          debugPrint('[AiNotesProvider] Inference timed out after 3 minutes');
          throw Exception('AI generation took too long. Please try a shorter document.');
        },
      );
      
      debugPrint('[AiNotesProvider] Request Completion: Note generated successfully.');

      final newNote = AiNote(
        id: _uuid.v4(),
        title: title.isEmpty ? 'Untitled Note' : title,
        content: generatedContent,
        type: type,
      );

      await saveNote(newNote);
      clearImagesAndPdf();
      return newNote;

    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // Remove 'Exception: '
      }
      _lastError = errorMessage;
      debugPrint('AiNotesProvider: Error generating notes: $errorMessage');
      return null;
    } finally {
      _isProcessing = false;
      _processingStatus = '';
      notifyListeners();
    }
  }

  Future<void> saveNote(AiNote note) async {
    await _dbService.insertAiNote(note.toMap(), note.id);
    await _loadNotes();
  }

  Future<void> updateNote(AiNote note) async {
    await _dbService.updateAiNote(note.toMap(), note.id);
    await _loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _dbService.deleteAiNote(id);
    await _loadNotes();
  }

  void updateAiProvider(AiProvider aiProvider) {
    _aiProvider = aiProvider;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
