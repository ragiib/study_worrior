import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../models/library_file.dart';
import '../../providers/library_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final LibraryFile file;

  const PdfViewerScreen({super.key, required this.file});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  late PdfTextSearchResult _searchResult;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _searchResult = PdfTextSearchResult();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    if (widget.file.lastReadPage > 0) {
      // Syncfusion uses 1-based indexing for jumpToPage
      _pdfViewerController.jumpToPage(widget.file.lastReadPage);
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    // Save the last read page when the page changes
    final provider = Provider.of<LibraryProvider>(context, listen: false);
    // Syncfusion provides 1-based indexing for page numbers
    provider.updateLastReadPage(widget.file, details.newPageNumber);
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      _searchResult.clear();
      setState(() {});
      return;
    }
    _searchResult = _pdfViewerController.searchText(query);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search in document...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  ),
                ),
                onSubmitted: (query) => _performSearch(query),
              )
            : Text(widget.file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _performSearch('');
                }
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            File(widget.file.path),
            controller: _pdfViewerController,
            canShowScrollHead: false,
            canShowScrollStatus: true,
            onDocumentLoaded: _onDocumentLoaded,
            onPageChanged: _onPageChanged,
          ),
          if (_searchResult.hasResult && _isSearching)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_searchResult.currentInstanceIndex} of ${_searchResult.totalInstanceCount}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_upward),
                            onPressed: () {
                              _searchResult.previousInstance();
                              setState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward),
                            onPressed: () {
                              _searchResult.nextInstance();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
