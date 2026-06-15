import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../models/ai_note_model.dart';
import '../../services/ai/ai_provider.dart';
import '../../services/ai/ollama_ai_provider.dart';
import '../../services/ocr_service.dart';
import '../../services/database_service.dart';

class AiNotesProvider extends ChangeNotifier {
  final DatabaseService _dbService;
  final OcrService _ocrService = OcrService();
  final AiProvider _aiProvider = OllamaAiProvider();
  final _uuid = const Uuid();

  List<AiNote> _notes = [];
  List<AiNote> get notes => _notes;

  final List<XFile> _selectedImages = [];
  List<XFile> get selectedImages => _selectedImages;

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

  void clearImages() {
    _selectedImages.clear();
    notifyListeners();
  }

  Future<AiNote?> generateNotes(NoteType type, String title) async {
    if (_selectedImages.isEmpty) return null;

    _isProcessing = true;
    _processingStatus = 'Extracting text from images...';
    notifyListeners();

    try {
      final imagePaths = _selectedImages.map((e) => e.path).toList();
      final extractedText = await _ocrService.extractTextFromMultipleImages(imagePaths);

      if (extractedText.trim().isEmpty) {
        throw Exception("No text could be extracted from the images.");
      }

      _processingStatus = 'Generating ${type.name} notes using AI...';
      notifyListeners();

      final generatedContent = await _aiProvider.generateNotes(
        extractedText: extractedText,
        type: type,
      );

      final newNote = AiNote(
        id: _uuid.v4(),
        title: title.isEmpty ? 'Untitled Note' : title,
        content: generatedContent,
        type: type,
      );

      await saveNote(newNote);
      clearImages();
      return newNote;

    } catch (e) {
      _lastError = e.toString();
      debugPrint('Error generating notes: $e');
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

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
