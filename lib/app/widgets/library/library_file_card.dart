import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/library_file.dart';

class LibraryFileCard extends StatelessWidget {
  final LibraryFile file;
  final bool isGrid;
  final VoidCallback onTap;
  final Function(String action) onAction;

  const LibraryFileCard({
    super.key,
    required this.file,
    this.isGrid = true,
    required this.onTap,
    required this.onAction,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getIcon() {
    if (file.name.toLowerCase().endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (file.name.toLowerCase().endsWith('.doc') || file.name.toLowerCase().endsWith('.docx')) {
      return Icons.description;
    } else if (file.name.toLowerCase().endsWith('.jpg') || file.name.toLowerCase().endsWith('.png')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open'),
              onTap: () {
                Navigator.pop(context);
                onAction('open');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                onAction('rename');
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move),
              title: const Text('Move'),
              onTap: () {
                Navigator.pop(context);
                onAction('move');
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                onAction('copy');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                onAction('share');
              },
            ),
            ListTile(
              leading: Icon(
                file.isFavorite ? Icons.star : Icons.star_border,
                color: file.isFavorite ? Colors.orange : null,
              ),
              title: Text(file.isFavorite ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () {
                Navigator.pop(context);
                onAction('favorite');
              },
            ),
            ListTile(
              leading: Icon(
                file.isDeleted ? Icons.delete_forever : Icons.delete,
                color: Colors.red,
              ),
              title: Text(
                file.isDeleted ? 'Delete Permanently' : 'Delete',
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                onAction('delete');
              },
            ),
            if (file.isDeleted)
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore'),
                onTap: () {
                  Navigator.pop(context);
                  onAction('restore');
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat.yMMMd().format(file.uploadDate);
    final formattedSize = _formatSize(file.sizeBytes);
    final typeText = file.fileType.toUpperCase();

    if (isGrid) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(50),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                  child: Center(
                    child: Icon(
                      _getIcon(),
                      size: 48,
                      color: theme.colorScheme.primary.withAlpha(200),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            file.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (file.isFavorite)
                          const Icon(Icons.star, size: 16, color: Colors.orange),
                        GestureDetector(
                          onTap: () => _showMenu(context),
                          child: const Icon(Icons.more_vert, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'By ${file.uploader}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$typeText • $formattedDate • $formattedSize',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(50),
          ),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIcon(),
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                'By ${file.uploader}',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text('$typeText • $formattedDate • $formattedSize', style: const TextStyle(fontSize: 11)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (file.isFavorite)
                const Icon(Icons.star, size: 20, color: Colors.orange),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showMenu(context),
              ),
            ],
          ),
        ),
      );
    }
  }
}
