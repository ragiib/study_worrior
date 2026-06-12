import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/ai_note_model.dart';
import '../providers/ai_notes_provider.dart';
import '../theme/app_theme.dart';

class AiNotesViewerScreen extends StatefulWidget {
  final AiNote note;

  const AiNotesViewerScreen({super.key, required this.note});

  @override
  State<AiNotesViewerScreen> createState() => _AiNotesViewerScreenState();
}

class _AiNotesViewerScreenState extends State<AiNotesViewerScreen> {
  late TextEditingController _contentController;
  late TextEditingController _titleController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note.content);
    _titleController = TextEditingController(text: widget.note.title);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Save changes
        widget.note.title = _titleController.text;
        widget.note.content = _contentController.text;
        Provider.of<AiNotesProvider>(context, listen: false).updateNote(widget.note);
      }
    });
  }

  void _shareNote() {
    Share.share('${widget.note.title}\n\n${widget.note.content}');
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(widget.note.title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Type: ${widget.note.typeLabel}', style: pw.TextStyle(color: PdfColors.grey)),
          pw.SizedBox(height: 20),
          pw.Paragraph(text: widget.note.content), // Basic PDF text rendering for markdown
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${widget.note.title.replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? TextField(
                controller: _titleController,
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'Note Title'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
            : Text(widget.note.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: _toggleEdit,
            tooltip: _isEditing ? 'Save' : 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareNote,
            tooltip: 'Share',
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: _isEditing
            ? TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Edit your notes here...',
                ),
                style: const TextStyle(height: 1.5),
              )
            : Markdown(
                data: widget.note.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  h2: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
      ),
    );
  }
}
