import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/library_file.dart';
import '../../providers/library_provider.dart';
import '../../widgets/library/library_category_card.dart';
import 'library_category_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  void _navigateToCategory(BuildContext context, String title, LibraryCategory? category, {bool isFavorites = false, bool isRecent = false, bool isDownloads = false, bool isTrash = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LibraryCategoryScreen(
          title: title,
          category: category,
          isFavorites: isFavorites,
          isRecent: isRecent,
          isDownloads: isDownloads,
          isTrash: isTrash,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'My Materials',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  LibraryCategoryCard(
                    title: 'Books',
                    icon: Icons.menu_book_rounded,
                    fileCount: provider.getCount(LibraryCategory.books),
                    color: Colors.blue,
                    onTap: () => _navigateToCategory(context, 'Books', LibraryCategory.books),
                  ),
                  LibraryCategoryCard(
                    title: 'Notes',
                    icon: Icons.edit_note_rounded,
                    fileCount: provider.getCount(LibraryCategory.notes),
                    color: Colors.orange,
                    onTap: () => _navigateToCategory(context, 'Notes', LibraryCategory.notes),
                  ),
                  LibraryCategoryCard(
                    title: 'PYQs',
                    icon: Icons.history_edu_rounded,
                    fileCount: provider.getCount(LibraryCategory.pyq),
                    color: Colors.deepPurple,
                    onTap: () => _navigateToCategory(context, 'PYQs', LibraryCategory.pyq),
                  ),
                  LibraryCategoryCard(
                    title: 'Assignments',
                    icon: Icons.assignment_rounded,
                    fileCount: provider.getCount(LibraryCategory.assignments),
                    color: Colors.green,
                    onTap: () => _navigateToCategory(context, 'Assignments', LibraryCategory.assignments),
                  ),
                  LibraryCategoryCard(
                    title: 'Syllabus',
                    icon: Icons.format_list_bulleted_rounded,
                    fileCount: provider.getCount(LibraryCategory.syllabus),
                    color: Colors.cyan,
                    onTap: () => _navigateToCategory(context, 'Syllabus', LibraryCategory.syllabus),
                  ),
                  LibraryCategoryCard(
                    title: 'Question Papers',
                    icon: Icons.quiz_rounded,
                    fileCount: provider.getCount(LibraryCategory.questionPapers),
                    color: Colors.redAccent,
                    onTap: () => _navigateToCategory(context, 'Question Papers', LibraryCategory.questionPapers),
                  ),
                  LibraryCategoryCard(
                    title: 'Other Resources',
                    icon: Icons.folder_copy_rounded,
                    fileCount: provider.getCount(LibraryCategory.other),
                    color: Colors.blueGrey,
                    onTap: () => _navigateToCategory(context, 'Other Resources', LibraryCategory.other),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Utilities',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  LibraryCategoryCard(
                    title: 'Favorites',
                    icon: Icons.star_rounded,
                    fileCount: provider.favoritesCount,
                    color: Colors.amber,
                    onTap: () => _navigateToCategory(context, 'Favorites', null, isFavorites: true),
                  ),
                  LibraryCategoryCard(
                    title: 'Recent',
                    icon: Icons.access_time_rounded,
                    fileCount: provider.recentCount,
                    color: Colors.teal,
                    onTap: () => _navigateToCategory(context, 'Recent', null, isRecent: true),
                  ),
                  LibraryCategoryCard(
                    title: 'Downloads',
                    icon: Icons.download_rounded,
                    fileCount: provider.downloadsCount,
                    color: Colors.indigo,
                    onTap: () => _navigateToCategory(context, 'Downloads', null, isDownloads: true),
                  ),
                  LibraryCategoryCard(
                    title: 'Trash',
                    icon: Icons.delete_outline_rounded,
                    fileCount: provider.trashCount,
                    color: Colors.red,
                    onTap: () => _navigateToCategory(context, 'Trash', null, isTrash: true),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
