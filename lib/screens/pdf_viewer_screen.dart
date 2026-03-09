import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdf_render/pdf_render.dart' as render;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
  bool _isNightMode = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showGoToPageDialog() {
    if (_pdfViewerController.pageCount == 0) return;
    final TextEditingController pageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to Page'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: pageController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '1 - ${_pdfViewerController.pageCount}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (value) {
            final int? page = int.tryParse(value);
            if (page != null &&
                page > 0 &&
                page <= _pdfViewerController.pageCount) {
              _pdfViewerController.jumpToPage(page);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final int? page = int.tryParse(pageController.text);
              if (page != null &&
                  page > 0 &&
                  page <= _pdfViewerController.pageCount) {
                _pdfViewerController.jumpToPage(page);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToJpg() async {
    if (_pdfViewerController.pageCount == 0) return;

    final TextEditingController pageController = TextEditingController(
      text: _pdfViewerController.pageNumber.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Page as JPG'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter page number to export:'),
            const SizedBox(height: 12),
            TextField(
              controller: pageController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '1 - ${_pdfViewerController.pageCount}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final int? pageNum = int.tryParse(pageController.text);
              if (pageNum != null &&
                  pageNum > 0 &&
                  pageNum <= _pdfViewerController.pageCount) {
                Navigator.pop(context);
                await _processExport(pageNum);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid page number')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Future<void> _processExport(int pageNumber) async {
    try {
      // Request permissions
      if (Platform.isAndroid) {
        if (!await Permission.storage.request().isGranted &&
            !await Permission.manageExternalStorage.request().isGranted) {
          // On Android 13+, storage permission might be denied but photos might work
          // or we can just proceed and see if gallery saver handles it.
        }
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final doc = await render.PdfDocument.openFile(widget.filePath);
      final page = await doc.getPage(pageNumber);

      final pageImage = await page.render(
        fullWidth: page.width * 4,
        fullHeight: page.height * 4,
      );

      final img = await pageImage.createImageDetached();
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name:
            "KTP_PDF_${p.basenameWithoutExtension(widget.filePath)}_page_$pageNumber",
      );

      Navigator.pop(context); // Close loading dialog

      if (result['isSuccess']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Page $pageNumber exported to gallery successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(result['errorMessage'] ?? 'Failed to save image');
      }

      await doc.dispose();
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting page: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () => _searchController.clear(),
                  ),
                ),
                onSubmitted: (value) async {
                  if (value.isNotEmpty) {
                    _searchResult = await _pdfViewerController.searchText(
                      value,
                    );
                    setState(() {});
                  }
                },
              )
            : Text(
                widget.fileName,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
        backgroundColor: _isNightMode ? Colors.black : Colors.red.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (_isSearching) ...[
            if (_searchResult.hasResult)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Text(
                    '${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.navigate_before),
              onPressed: () {
                _searchResult.previousInstance();
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.navigate_next),
              onPressed: () {
                _searchResult.nextInstance();
                setState(() {});
              },
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
            IconButton(
              icon: Icon(_isNightMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _isNightMode = !_isNightMode),
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
            IconButton(
              icon: const Icon(Icons.image_outlined),
              tooltip: 'Export Page as JPG',
              onPressed: _exportToJpg,
            ),
          ],
        ],
      ),
      body: ColorFiltered(
        colorFilter: ColorFilter.matrix(
          _isNightMode
              ? [
                  -1, 0, 0, 0, 255, // R
                  0, -1, 0, 0, 255, // G
                  0, 0, -1, 0, 255, // B
                  0, 0, 0, 1, 0, // A
                ]
              : [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0],
        ),
        child: SfPdfViewer.file(
          File(widget.filePath),
          controller: _pdfViewerController,
          key: _pdfViewerKey,
          enableTextSelection: true,
        ),
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
