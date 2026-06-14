import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ai_notes_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_page_header.dart';
import 'ai_notes_viewer_screen.dart';

class SavedNotesScreen extends StatefulWidget {
  const SavedNotesScreen({super.key});

  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AiNotesProvider>(
        builder: (context, provider, _) {
          final filteredNotes = provider.notes.where((note) {
            return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   note.content.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              const PremiumPageHeader(
                topLabel: 'Your Library',
                emoji: '📚',
                title: 'Saved Notes',
                subtitle: 'Access your generated AI notes.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: filteredNotes.isEmpty
                    ? Center(
                        child: Text(
                          provider.notes.isEmpty
                              ? 'No saved notes yet.\nGenerate some AI notes!'
                              : 'No notes match your search.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = filteredNotes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withAlpha(30),
                                child: const Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                              ),
                              title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('${note.typeLabel} • ${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}'),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  provider.deleteNote(note.id);
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AiNotesViewerScreen(note: note),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
