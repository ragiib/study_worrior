import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../services/ai/ai_provider.dart';
import '../../services/ocr_service.dart';
import '../../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_page_header.dart';
import '../widgets/animated_ai_loader.dart';

class AiDoubtSolverScreen extends StatefulWidget {
  const AiDoubtSolverScreen({super.key});

  @override
  State<AiDoubtSolverScreen> createState() => _AiDoubtSolverScreenState();
}

class _AiDoubtSolverScreenState extends State<AiDoubtSolverScreen> {
  final TextEditingController _questionController = TextEditingController();
  XFile? _selectedImage;
  PlatformFile? _selectedPdf;
  
  final OcrService _ocrService = OcrService();
  final PdfService _pdfService = PdfService();

  bool _isProcessing = false;
  bool _isCompletingSequence = false;
  String _processingStatus = '';
  String? _answer;
  String? _error;

  @override
  void dispose() {
    _questionController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _answer = null;
        _error = null;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _answer = null;
      _error = null;
    });
  }

  Future<void> _pickPdf() async {
    final pdf = await _pdfService.pickPdf();
    if (pdf != null) {
      setState(() {
        _selectedPdf = pdf;
        _answer = null;
        _error = null;
      });
    }
  }

  void _removePdf() {
    setState(() {
      _selectedPdf = null;
      _answer = null;
      _error = null;
    });
  }

  Future<void> _askQuestion(String question) async {
    if (_selectedImage == null && _selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image or a PDF first.')),
      );
      return;
    }
    
    if (question.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question.')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Processing document...';
      _answer = null;
      _error = null;
    });

    try {
      String extractedText = '';
      
      if (_selectedPdf != null) {
        setState(() {
          _processingStatus = 'Extracting text from PDF...';
        });
        extractedText += await _pdfService.extractTextFromPdf(_selectedPdf!.path!) + '\n\n';
      }
      
      if (_selectedImage != null) {
        setState(() {
          _processingStatus = 'Extracting text from image...';
        });
        extractedText += await _ocrService.extractTextFromImage(_selectedImage!.path);
      }

      if (extractedText.trim().isEmpty) {
        throw Exception("No text could be extracted from the file.");
      }

      setState(() {
        _processingStatus = 'Solving doubt using AI...';
      });

      final aiProvider = context.read<AiProvider>();
      final result = await aiProvider.answerDoubt(
        contextText: extractedText,
        question: question,
      );

      setState(() {
        _isCompletingSequence = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 2200));
      
      if (mounted) {
        setState(() {
          _isCompletingSequence = false;
          _answer = result;
        });
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      setState(() {
        _error = errorMessage;
      });
    } finally {
      setState(() {
        _isProcessing = false;
        _isCompletingSequence = false;
      });
    }
  }

  void _onQuickAction(String action) {
    _questionController.text = action;
    _askQuestion(action);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isProcessing || _isCompletingSequence
        ? Center(
            child: AnimatedAiLoader(
              customText: _isCompletingSequence ? null : _processingStatus,
              isSuccessSequence: _isCompletingSequence,
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PremiumPageHeader(
                  topLabel: 'AI Doubt Solver',
                  emoji: '🤔',
                  title: 'Ask Anything',
                  subtitle: 'Upload a picture of your material and ask away.',
                ),
                const SizedBox(height: 24),
                
                // Image Selection
                if (_selectedImage == null && _selectedPdf == null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickPdf(),
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
                          onPressed: () => _pickImage(ImageSource.gallery),
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
                          onPressed: () => _pickImage(ImageSource.camera),
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
                ] else ...[
                  if (_selectedPdf != null)
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
                                  _selectedPdf!.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _pdfService.formatFileSize(_selectedPdf!.size),
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _removePdf,
                            color: Colors.red.shade800,
                          ),
                        ],
                      ),
                    ),
                  
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withAlpha(50)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: kIsWeb
                              ? Image.network(
                                  _selectedImage!.path,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_selectedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _removeImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
                
                const SizedBox(height: 24),
                
                // Question Input
                TextField(
                  controller: _questionController,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'What is your doubt?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                      onPressed: () => _askQuestion(_questionController.text),
                    ),
                  ),
                  onSubmitted: _askQuestion,
                ),
                
                const SizedBox(height: 16),
                
                // Quick Actions
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickAction('Explain Simpler'),
                      const SizedBox(width: 8),
                      _buildQuickAction('Give Example'),
                      const SizedBox(width: 8),
                      _buildQuickAction('Summarize'),
                      const SizedBox(width: 8),
                      _buildQuickAction('Quiz Me'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Error Display
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Answer Display
                if (_answer != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'AI Answer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        MarkdownBody(
                          data: _answer!,
                          selectable: true,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildQuickAction(String action) {
    return ActionChip(
      label: Text(action),
      backgroundColor: AppTheme.primaryColor.withAlpha(20),
      labelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
      side: BorderSide.none,
      onPressed: () => _onQuickAction(action),
    );
  }
}
