import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showGoToPageDialog() {
    final TextEditingController pageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: pageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText:
                'Enter page number (1 - ${_pdfViewerController.pageCount})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final int? page = int.tryParse(pageController.text);
              if (page != null &&
                  page > 0 &&
                  page <= _pdfViewerController.pageCount) {
                _pdfViewerController.jumpToPage(page);
                Navigator.pop(context);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onSubmitted: (value) async {
                  _searchResult = await _pdfViewerController.searchText(value);
                  setState(() {});
                },
              )
            : Text(
                widget.fileName,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.navigate_before),
              onPressed: () => _searchResult.previousInstance(),
            ),
            IconButton(
              icon: const Icon(Icons.navigate_next),
              onPressed: () => _searchResult.nextInstance(),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchResult.clear();
                  _searchController.clear();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(Icons.tag),
              onPressed: _showGoToPageDialog,
            ),
            PopupMenuButton<double>(
              icon: const Icon(Icons.zoom_in),
              onSelected: (value) => _pdfViewerController.zoomLevel = value,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 1.0, child: Text('100%')),
                const PopupMenuItem(value: 1.5, child: Text('150%')),
                const PopupMenuItem(value: 2.0, child: Text('200%')),
                const PopupMenuItem(value: 3.0, child: Text('300%')),
              ],
            ),
          ],
        ],
      ),
      body: SfPdfViewer.file(
        File(widget.filePath),
        controller: _pdfViewerController,
        key: _pdfViewerKey,
        enableTextSelection: true,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "scroll_up",
            onPressed: () => _pdfViewerController.previousPage(),
            child: const Icon(Icons.keyboard_arrow_up),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "scroll_down",
            onPressed: () => _pdfViewerController.nextPage(),
            child: const Icon(Icons.keyboard_arrow_down),
          ),
        ],
      ),
    );
  }
}
