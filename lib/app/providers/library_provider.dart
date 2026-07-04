// ============================================================================
// Library Provider
// Manages the state for the Library feature.
// ============================================================================

import 'package:flutter/material.dart';

import '../../models/library_file.dart';
import '../../services/library_service.dart';

enum SortOption {
  dateDesc,
  dateAsc,
  nameAsc,
  nameDesc,
  sizeDesc,
  sizeAsc,
}

class LibraryProvider extends ChangeNotifier {
  final LibraryService _libraryService;
  
  List<LibraryFile> _allFiles = [];
  bool _isLoading = false;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.dateDesc;
  bool _isGridView = true;

  LibraryProvider(this._libraryService);

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;
  bool get isGridView => _isGridView;

  Future<void> loadFiles() async {
    _isLoading = true;
    notifyListeners();

    _allFiles = await _libraryService.getAllFiles();

    _isLoading = false;
    notifyListeners();
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  // ── File Queries ──────────────────────────────────────────────────────────

  List<LibraryFile> _applySearchAndSort(List<LibraryFile> files) {
    List<LibraryFile> result = List.from(files);

    if (_searchQuery.isNotEmpty) {
      result = result.where((file) => 
        file.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    switch (_sortOption) {
      case SortOption.dateDesc:
        result.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
        break;
      case SortOption.dateAsc:
        result.sort((a, b) => a.uploadDate.compareTo(b.uploadDate));
        break;
      case SortOption.nameAsc:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameDesc:
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortOption.sizeDesc:
        result.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
      case SortOption.sizeAsc:
        result.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
        break;
    }

    return result;
  }

  List<LibraryFile> getFilesByCategory(LibraryCategory category) {
    return _applySearchAndSort(
      _allFiles.where((f) => f.category == category && !f.isDeleted).toList()
    );
  }

  List<LibraryFile> getFavorites() {
    return _applySearchAndSort(
      _allFiles.where((f) => f.isFavorite && !f.isDeleted).toList()
    );
  }

  List<LibraryFile> getRecent() {
    final now = DateTime.now();
    return _applySearchAndSort(
      _allFiles.where((f) {
        if (f.isDeleted) return false;
        // Consider recent if uploaded or opened in the last 7 days
        final isUploadedRecently = now.difference(f.uploadDate).inDays <= 7;
        final isOpenedRecently = f.lastOpenedDate != null && now.difference(f.lastOpenedDate!).inDays <= 7;
        return isUploadedRecently || isOpenedRecently;
      }).toList()
    );
  }

  List<LibraryFile> getDownloads() {
    // For now, downloads can just be all files not deleted, or you could add a 'isDownloaded' flag
    // Currently mapping it to all files as a placeholder until actual remote downloads exist
    return _applySearchAndSort(
      _allFiles.where((f) => !f.isDeleted).toList()
    );
  }

  List<LibraryFile> getTrash() {
    return _applySearchAndSort(
      _allFiles.where((f) => f.isDeleted).toList()
    );
  }

  // Count getters for the dashboard
  int getCount(LibraryCategory category) => _allFiles.where((f) => f.category == category && !f.isDeleted).length;
  int get favoritesCount => _allFiles.where((f) => f.isFavorite && !f.isDeleted).length;
  int get recentCount => getRecent().length;
  int get downloadsCount => getDownloads().length;
  int get trashCount => _allFiles.where((f) => f.isDeleted).length;

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> uploadFile(LibraryCategory category) async {
    final newFile = await _libraryService.pickAndSaveFile(category);
    if (newFile != null) {
      _allFiles.add(newFile);
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(LibraryFile file) async {
    final updatedFile = file.copyWith(isFavorite: !file.isFavorite);
    await _libraryService.updateFile(updatedFile);
    
    final index = _allFiles.indexWhere((f) => f.id == file.id);
    if (index != -1) {
      _allFiles[index] = updatedFile;
      notifyListeners();
    }
  }

  Future<void> renameFile(LibraryFile file, String newName) async {
    await _libraryService.renameFile(file, newName);
    final index = _allFiles.indexWhere((f) => f.id == file.id);
    if (index != -1) {
      _allFiles[index] = _allFiles[index].copyWith(name: newName);
      notifyListeners();
    }
  }

  Future<void> deleteFile(LibraryFile file) async {
    await _libraryService.deleteFile(file);
    if (file.isDeleted) {
      // Permanently delete
      _allFiles.removeWhere((f) => f.id == file.id);
    } else {
      // Move to trash
      final index = _allFiles.indexWhere((f) => f.id == file.id);
      if (index != -1) {
        _allFiles[index] = _allFiles[index].copyWith(isDeleted: true);
      }
    }
    notifyListeners();
  }

  Future<void> restoreFile(LibraryFile file) async {
    await _libraryService.restoreFile(file);
    final index = _allFiles.indexWhere((f) => f.id == file.id);
    if (index != -1) {
      _allFiles[index] = _allFiles[index].copyWith(isDeleted: false);
      notifyListeners();
    }
  }

  Future<void> markAsOpened(LibraryFile file) async {
    await _libraryService.markFileAsOpened(file);
    final index = _allFiles.indexWhere((f) => f.id == file.id);
    if (index != -1) {
      _allFiles[index] = _allFiles[index].copyWith(lastOpenedDate: DateTime.now());
      notifyListeners();
    }
  }

  Future<void> updateLastReadPage(LibraryFile file, int page) async {
    final updatedFile = file.copyWith(lastReadPage: page);
    await _libraryService.updateFile(updatedFile);
    final index = _allFiles.indexWhere((f) => f.id == file.id);
    if (index != -1) {
      _allFiles[index] = updatedFile;
      notifyListeners();
    }
  }
}
