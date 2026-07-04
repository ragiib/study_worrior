// ============================================================================
// Library Service
// Handles file picking, local storage, and metadata persistence.
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/library_file.dart';

class LibraryService {
  bool _initialized = false;
  late Box<String> _libraryBox;
  late Directory _appDocDir;

  Future<void> initialize() async {
    if (_initialized) return;

    _libraryBox = await Hive.openBox<String>('library_files');
    _appDocDir = await getApplicationDocumentsDirectory();

    // Ensure a 'library' directory exists
    final libraryDir = Directory(p.join(_appDocDir.path, 'library'));
    if (!await libraryDir.exists()) {
      await libraryDir.create(recursive: true);
    }

    _initialized = true;
  }

  // ── File Uploading ────────────────────────────────────────────────────────

  Future<LibraryFile?> pickAndSaveFile(LibraryCategory category) async {
    if (!_initialized) return null;

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.any, // Allow any document type (PDF, docx, etc.) for now
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        final file = File(sourcePath);
        final fileName = result.files.single.name;
        final sizeBytes = await file.length();
        
        // Destination path in app directory
        final ext = p.extension(fileName);
        final baseName = p.basenameWithoutExtension(fileName);
        final uuid = const Uuid().v4();
        
        // Make the file name unique in local storage
        final newFileName = '${baseName}_$uuid$ext';
        final destPath = p.join(_appDocDir.path, 'library', newFileName);
        
        // Copy file
        await file.copy(destPath);
        
        // Create model
        final libraryFile = LibraryFile(
          id: uuid,
          name: fileName,
          path: destPath,
          sizeBytes: sizeBytes,
          uploadDate: DateTime.now(),
          category: category,
          fileType: ext.replaceAll('.', '').toLowerCase().isEmpty ? 'unknown' : ext.replaceAll('.', '').toLowerCase(),
          uploader: 'Current User',
        );

        // Save metadata
        await _saveFileMetadata(libraryFile);
        return libraryFile;
      }
    } catch (e) {
      print('Error picking file: $e');
    }
    return null;
  }

  // ── Metadata Operations ───────────────────────────────────────────────────

  Future<void> _saveFileMetadata(LibraryFile file) async {
    await _libraryBox.put(file.id, jsonEncode(file.toMap()));
  }

  Future<List<LibraryFile>> getAllFiles() async {
    if (!_initialized) return [];
    
    return _libraryBox.values.map((jsonStr) {
      return LibraryFile.fromMap(jsonDecode(jsonStr));
    }).toList();
  }

  Future<void> updateFile(LibraryFile file) async {
    if (!_initialized) return;
    await _saveFileMetadata(file);
  }

  Future<void> deleteFile(LibraryFile file) async {
    if (!_initialized) return;
    
    // If it's already in trash (isDeleted = true), permanently delete it
    if (file.isDeleted) {
      final localFile = File(file.path);
      if (await localFile.exists()) {
        await localFile.delete();
      }
      await _libraryBox.delete(file.id);
    } else {
      // Move to trash
      final updatedFile = file.copyWith(isDeleted: true);
      await updateFile(updatedFile);
    }
  }

  Future<void> restoreFile(LibraryFile file) async {
    if (!_initialized) return;
    final updatedFile = file.copyWith(isDeleted: false);
    await updateFile(updatedFile);
  }

  Future<void> renameFile(LibraryFile file, String newName) async {
    if (!_initialized) return;
    final updatedFile = file.copyWith(name: newName);
    await updateFile(updatedFile);
  }

  // Records when the file was last opened
  Future<void> markFileAsOpened(LibraryFile file) async {
    if (!_initialized) return;
    final updatedFile = file.copyWith(lastOpenedDate: DateTime.now());
    await updateFile(updatedFile);
  }
}
