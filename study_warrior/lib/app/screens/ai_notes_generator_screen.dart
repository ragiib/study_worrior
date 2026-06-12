import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/ai_note_model.dart';
import '../providers/ai_notes_provider.dart';
import '../theme/app_theme.dart';
import 'ai_notes_viewer_screen.dart';

class AiNotesGeneratorScreen extends StatefulWidget {
  const AiNotesGeneratorScreen({super.key});

  @override
  State<AiNotesGeneratorScreen> createState() => _AiNotesGeneratorScreenState();
}

class _AiNotesGeneratorScreenState extends State<AiNotesGeneratorScreen> {
  NoteType _selectedType = NoteType.summary;
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _generateNotes(BuildContext context) async {
    final provider = Provider.of<AiNotesProvider>(context, listen: false);
    if (provider.selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image.')),
      );
      return;
    }

    final note = await provider.generateNotes(_selectedType, _titleController.text);
    if (note != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AiNotesViewerScreen(note: note),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate notes. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Notes Generator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AiNotesProvider>(
        builder: (context, provider, _) {
          if (provider.isProcessing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    provider.processingStatus,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Select Images',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => provider.pickImages(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => provider.pickImages(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (provider.selectedImages.isNotEmpty) ...[
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withAlpha(50)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              // For web compatibility we should use network image, but for simplicity we assume file exists or we can use bytes
                              child: Image.file(
                                File(provider.selectedImages[index].path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => provider.removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                Text(
                  '2. Output Format',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withAlpha(50)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<NoteType>(
                      value: _selectedType,
                      isExpanded: true,
                      items: NoteType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getTypeLabel(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  '3. Note Title (Optional)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Chapter 4: Thermodynamics',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.selectedImages.isEmpty
                        ? null
                        : () => _generateNotes(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Generate AI Notes 🚀',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getTypeLabel(NoteType type) {
    switch (type) {
      case NoteType.summary: return 'Short Summary';
      case NoteType.detailed: return 'Detailed Notes';
      case NoteType.bulletPoints: return 'Bullet Point Revision Notes';
      case NoteType.keyConcepts: return 'Key Concepts';
      case NoteType.definitions: return 'Important Definitions';
      case NoteType.formulas: return 'Formula Extraction';
      case NoteType.examOriented: return 'Exam-Oriented Notes';
      case NoteType.mcqs: return 'MCQs with answers';
    }
  }
}
