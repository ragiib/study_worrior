import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/library_file.dart';
import '../../providers/library_provider.dart';
import '../../widgets/library/library_file_card.dart';
import 'pdf_viewer_screen.dart';

class LibraryCategoryScreen extends StatefulWidget {
  final String title;
  final LibraryCategory? category;
  final bool isFavorites;
  final bool isRecent;
  final bool isDownloads;
  final bool isTrash;

  const LibraryCategoryScreen({
    super.key,
    required this.title,
    this.category,
    this.isFavorites = false,
    this.isRecent = false,
    this.isDownloads = false,
    this.isTrash = false,
  });

  @override
  State<LibraryCategoryScreen> createState() => _LibraryCategoryScreenState();
}

class _LibraryCategoryScreenState extends State<LibraryCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleAction(BuildContext context, LibraryFile file, String action) {
    final provider = Provider.of<LibraryProvider>(context, listen: false);
    
    switch (action) {
      case 'open':
        _openFile(file);
        break;
      case 'rename':
        _showRenameDialog(context, file, provider);
        break;
      case 'move':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Move feature coming soon')),
        );
        break;
      case 'copy':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copy feature coming soon')),
        );
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share feature coming soon')),
        );
        break;
      case 'favorite':
        provider.toggleFavorite(file);
        break;
      case 'delete':
        provider.deleteFile(file);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(file.isDeleted ? 'File permanently deleted' : 'File moved to trash'),
          ),
        );
        break;
      case 'restore':
        provider.restoreFile(file);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File restored')),
        );
        break;
    }
  }

  void _openFile(LibraryFile file) {
    Provider.of<LibraryProvider>(context, listen: false).markAsOpened(file);
    
    if (file.name.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(file: file),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unsupported file format')),
      );
    }
  }

  void _showRenameDialog(BuildContext context, LibraryFile file, LibraryProvider provider) {
    final nameController = TextEditingController(text: file.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'New name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                provider.renameFile(file, newName);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Consumer<LibraryProvider>(
            builder: (context, provider, _) => IconButton(
              icon: Icon(provider.isGridView ? Icons.view_list : Icons.grid_view),
              onPressed: () => provider.toggleViewMode(),
            ),
          ),
          Consumer<LibraryProvider>(
            builder: (context, provider, _) => PopupMenuButton<SortOption>(
              icon: const Icon(Icons.sort),
              onSelected: (option) => provider.setSortOption(option),
              itemBuilder: (context) => const [
                PopupMenuItem(value: SortOption.dateDesc, child: Text('Newest first')),
                PopupMenuItem(value: SortOption.dateAsc, child: Text('Oldest first')),
                PopupMenuItem(value: SortOption.nameAsc, child: Text('Name A-Z')),
                PopupMenuItem(value: SortOption.nameDesc, child: Text('Name Z-A')),
                PopupMenuItem(value: SortOption.sizeDesc, child: Text('Largest first')),
                PopupMenuItem(value: SortOption.sizeAsc, child: Text('Smallest first')),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, provider, child) {
          List<LibraryFile> files;
          if (widget.isFavorites) {
            files = provider.getFavorites();
          } else if (widget.isRecent) {
            files = provider.getRecent();
          } else if (widget.isDownloads) {
            files = provider.getDownloads();
          } else if (widget.isTrash) {
            files = provider.getTrash();
          } else if (widget.category != null) {
            files = provider.getFilesByCategory(widget.category!);
          } else {
            files = [];
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => provider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search in ${widget.title}...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              Expanded(
                child: files.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 80,
                              color: theme.colorScheme.primary.withAlpha(100),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No files found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : provider.isGridView
                        ? GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: files.length,
                            itemBuilder: (context, index) {
                              return LibraryFileCard(
                                file: files[index],
                                isGrid: true,
                                onTap: () => _openFile(files[index]),
                                onAction: (action) => _handleAction(context, files[index], action),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: files.length,
                            itemBuilder: (context, index) {
                              return LibraryFileCard(
                                file: files[index],
                                isGrid: false,
                                onTap: () => _openFile(files[index]),
                                onAction: (action) => _handleAction(context, files[index], action),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: (widget.category != null && !widget.isTrash)
          ? FloatingActionButton.extended(
              onPressed: () {
                Provider.of<LibraryProvider>(context, listen: false).uploadFile(widget.category!);
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            )
          : null,
    );
  }
}
