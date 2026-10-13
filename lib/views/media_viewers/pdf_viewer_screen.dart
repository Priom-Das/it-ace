// File: lib/views/media_viewers/pdf_viewer_screen.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../ai_assistant/draggable_ai_fab.dart';

// English Comment: Cross-platform PDF viewer. The PDF is downloaded first and then shown inside this same page
// on mobile (local file) and on web/PWA (in memory), so the AI assistant button works on top of it everywhere.
class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  // Mobile: path of the downloaded file.
  String? _localFilePath;
  // Web / PWA: the downloaded PDF kept in memory.
  Uint8List? _webBytes;
  String? _webError;

  bool _isDownloading = true;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadWebPdf();
    } else {
      _checkAndAutoDownloadPdf();
    }
  }

  // ---------------------------------------------------------------- Web / PWA

  // English Comment: Downloads the PDF bytes (the service worker keeps a copy, so it also opens offline later).
  Future<void> _loadWebPdf() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _webError = null;
    });

    try {
      final response = await Dio().get<List<int>>(
        widget.pdfUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      final data = response.data;
      if (data == null || data.isEmpty) {
        throw Exception('Empty file');
      }
      if (!mounted) return;
      setState(() {
        _webBytes = Uint8List.fromList(data);
        _isDownloading = false;
      });
    } catch (e) {
      debugPrint('Web PDF load error: $e');
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _webError = 'Could not load this PDF. If you are offline, open it once while online first.';
      });
    }
  }

  Future<void> _openInBrowser() async {
    final Uri url = Uri.parse(widget.pdfUrl);
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the PDF.')),
      );
    }
  }

  Widget _buildProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress is unknown until the server reports the file size, so show a spinner meanwhile.
          CircularProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress : null),
          const SizedBox(height: 16),
          Text(_downloadProgress > 0
              ? 'Downloading PDF: ${(_downloadProgress * 100).toStringAsFixed(0)}%'
              : 'Loading PDF...'),
        ],
      ),
    );
  }

  Widget _buildWebBody() {
    if (_isDownloading) return _buildProgress();

    final bytes = _webBytes;
    if (bytes != null) {
      return PdfViewer.data(bytes, sourceName: widget.pdfUrl);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_webError ?? 'Could not load this PDF.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadWebPdf,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
            TextButton(
              onPressed: _openInBrowser,
              child: const Text('Open in browser'),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------- Mobile

  // English Comment: Automatically checks local storage or triggers download immediately for mobile view.
  Future<void> _checkAndAutoDownloadPdf() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final rawFileName = widget.pdfUrl.split('/').last.split('?').first;
      final fileName = Uri.decodeComponent(rawFileName);
      final file = File('${dir.path}/$fileName');

      if (await file.exists()) {
        setState(() {
          _localFilePath = file.path;
          _isDownloading = false;
        });
      } else {
        await _downloadPdf();
      }
    } catch (e) {
      debugPrint('Auto download check error: $e');
      setState(() {
        _isDownloading = false;
      });
    }
  }

  // English Comment: Downloads PDF file using Dio with progress tracking on mobile.
  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final rawFileName = widget.pdfUrl.split('/').last.split('?').first;
      final fileName = Uri.decodeComponent(rawFileName);
      final filePath = '${dir.path}/$fileName';

      Dio dio = Dio();
      await dio.download(
        widget.pdfUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        _localFilePath = filePath;
        _isDownloading = false;
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Widget _buildMobileBody() {
    if (_isDownloading) return _buildProgress();
    if (_localFilePath != null) return PDFView(filePath: _localFilePath!);
    return Center(
      child: ElevatedButton.icon(
        onPressed: _downloadPdf,
        icon: const Icon(Icons.download),
        label: const Text('Download and Open PDF'),
      ),
    );
  }

  // ------------------------------------------------------------------- Shared

  void _openAiAssistantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const AiAssistantScreen(isEmbedded: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openInBrowser,
              tooltip: 'Open / download in browser',
            )
          else if (_localFilePath != null)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
      // The AI button sits in the same Stack on every platform. DraggableAiFab positions itself.
      body: Stack(
        children: [
          Positioned.fill(
            child: kIsWeb ? _buildWebBody() : _buildMobileBody(),
          ),
          DraggableAiFab(
            onPressed: () => _openAiAssistantSheet(context),
          ),
        ],
      ),
    );
  }
}