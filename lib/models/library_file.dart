// ============================================================================
// Library File Model
// Represents a file in the user's digital library.
// ============================================================================

enum LibraryCategory {
  books,
  notes,
  pyq,
  assignments,
  syllabus,
  questionPapers,
  other;

  String get displayName {
    switch (this) {
      case LibraryCategory.books:
        return 'Books';
      case LibraryCategory.notes:
        return 'Notes';
      case LibraryCategory.pyq:
        return 'PYQs';
      case LibraryCategory.assignments:
        return 'Assignments';
      case LibraryCategory.syllabus:
        return 'Syllabus';
      case LibraryCategory.questionPapers:
        return 'Question Papers';
      case LibraryCategory.other:
        return 'Other Resources';
    }
  }
}

class LibraryFile {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final DateTime uploadDate;
  final DateTime? lastOpenedDate;
  final LibraryCategory category;
  final bool isFavorite;
  final bool isDeleted;
  final String uploader;
  final String fileType;
  final int lastReadPage;

  const LibraryFile({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.uploadDate,
    required this.category,
    this.lastOpenedDate,
    this.isFavorite = false,
    this.isDeleted = false,
    this.uploader = 'Current User',
    this.fileType = 'pdf',
    this.lastReadPage = 0,
  });

  LibraryFile copyWith({
    String? id,
    String? name,
    String? path,
    int? sizeBytes,
    DateTime? uploadDate,
    DateTime? lastOpenedDate,
    LibraryCategory? category,
    bool? isFavorite,
    bool? isDeleted,
    String? uploader,
    String? fileType,
    int? lastReadPage,
  }) {
    return LibraryFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uploadDate: uploadDate ?? this.uploadDate,
      lastOpenedDate: lastOpenedDate ?? this.lastOpenedDate,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
      uploader: uploader ?? this.uploader,
      fileType: fileType ?? this.fileType,
      lastReadPage: lastReadPage ?? this.lastReadPage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'sizeBytes': sizeBytes,
      'uploadDate': uploadDate.toIso8601String(),
      'lastOpenedDate': lastOpenedDate?.toIso8601String(),
      'category': category.name,
      'isFavorite': isFavorite,
      'isDeleted': isDeleted,
      'uploader': uploader,
      'fileType': fileType,
      'lastReadPage': lastReadPage,
    };
  }

  factory LibraryFile.fromMap(Map<String, dynamic> map) {
    return LibraryFile(
      id: map['id'],
      name: map['name'],
      path: map['path'],
      sizeBytes: map['sizeBytes'],
      uploadDate: DateTime.parse(map['uploadDate']),
      lastOpenedDate: map['lastOpenedDate'] != null 
          ? DateTime.parse(map['lastOpenedDate']) 
          : null,
      category: LibraryCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => LibraryCategory.other,
      ),
      isFavorite: map['isFavorite'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      uploader: map['uploader'] ?? 'Current User',
      fileType: map['fileType'] ?? 'pdf',
      lastReadPage: map['lastReadPage'] ?? 0,
    );
  }
}
