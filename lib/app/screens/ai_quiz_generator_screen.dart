import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/ai_quiz_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_page_header.dart';
import '../widgets/animated_ai_loader.dart';
import 'quiz_playing_screen.dart';

class AiQuizGeneratorScreen extends StatefulWidget {
  const AiQuizGeneratorScreen({super.key});

  @override
  State<AiQuizGeneratorScreen> createState() => _AiQuizGeneratorScreenState();
}

class _AiQuizGeneratorScreenState extends State<AiQuizGeneratorScreen> {
  final TextEditingController _textController = TextEditingController();
  int _numQuestions = 5;
  String _difficulty = 'Medium';
  String _type = 'Multiple Choice';
  bool _isCompletingSequence = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _generateQuiz(BuildContext context) async {
    final provider = Provider.of<AiQuizProvider>(context, listen: false);
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final quiz = await provider.generateQuiz(
      manualText: _textController.text,
      numQuestions: _numQuestions,
      difficulty: _difficulty,
      type: _type,
    );

    if (quiz != null && mounted) {
      setState(() {
        _isCompletingSequence = true;
      });
      // Wait for the final animation sequence to finish
      await Future.delayed(const Duration(milliseconds: 2200));
      
      if (mounted) {
        setState(() {
          _isCompletingSequence = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPlayingScreen(quiz: quiz),
          ),
        );
      }
    } else if (mounted) {
      final error = provider.lastError ?? 'Unknown error. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error,
            style: const TextStyle(height: 1.4),
          ),
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AiQuizProvider>(
        builder: (context, provider, _) {
          if (provider.isProcessing || _isCompletingSequence) {
            return Center(
              child: AnimatedAiLoader(
                customText: _isCompletingSequence ? null : provider.processingStatus,
                isSuccessSequence: _isCompletingSequence,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PremiumPageHeader(
                  topLabel: 'AI Quiz',
                  emoji: '🧠',
                  title: 'Generator',
                  subtitle: 'Test your knowledge instantly.',
                ),
                const SizedBox(height: 24),

                Text(
                  '1. Provide Source Material',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Image Selection
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => provider.pickPdf(),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 8),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Recommended: Upload a PDF for larger or multi-page study material.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (provider.selectedPdf != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red.shade600, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.selectedPdf!.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                provider.formatFileSize(provider.selectedPdf!.size),
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => provider.removePdf(),
                          color: Colors.red.shade800,
                        ),
                      ],
                    ),
                  ),
                ],

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
                              child: kIsWeb
                                  ? Image.network(
                                      provider.selectedImages[index].path,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                                    )
                                  : Image.file(
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
                  const SizedBox(height: 12),
                ],

                const Text(
                  'OR paste text manually:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Paste paragraphs, articles, or notes here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  '2. Configure Quiz',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                _buildDropdownRow(
                  label: 'Questions',
                  value: _numQuestions,
                  items: [5, 10, 15, 20],
                  onChanged: (val) {
                    if (val != null) setState(() => _numQuestions = val as int);
                  },
                ),
                const SizedBox(height: 12),
                
                _buildDropdownRow(
                  label: 'Difficulty',
                  value: _difficulty,
                  items: ['Easy', 'Medium', 'Hard', 'Mixed'],
                  onChanged: (val) {
                    if (val != null) setState(() => _difficulty = val as String);
                  },
                ),
                const SizedBox(height: 12),
                
                _buildDropdownRow(
                  label: 'Question Type',
                  value: _type,
                  items: ['Multiple Choice', 'True/False', 'Mixed'],
                  onChanged: (val) {
                    if (val != null) setState(() => _type = val as String);
                  },
                ),
                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _generateQuiz(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Create Quiz 🚀',
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

  Widget _buildDropdownRow({
    required String label,
    required dynamic value,
    required List<dynamic> items,
    required void Function(dynamic) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withAlpha(50)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<dynamic>(
                value: value,
                isExpanded: true,
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item.toString()),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
