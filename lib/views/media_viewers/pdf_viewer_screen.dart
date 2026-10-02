// File: lib/views/media_viewers/pdf_viewer_screen.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../ai_assistant/draggable_ai_fab.dart';

// Conditional import to safely handle web and non-web platforms without compile errors
import 'pdf_viewer_stub.dart' 
    if (dart.library.html) 'pdf_viewer_web.dart';

// English Comment: Robust cross-platform PDF Viewer supporting direct object embedding for web and local storage for mobile.
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
  String? _localFilePath;
  bool _isDownloading = true;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _checkAndAutoDownloadPdf();
    } else {
      setState(() {
        _isDownloading = false;
      });
    }
  }

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

  Future<void> _downloadOrOpenWebPdf() async {
    final Uri url = Uri.parse(widget.pdfUrl);
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Successfully launched
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not process PDF action.')),
        );
      }
    }
  }

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
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadOrOpenWebPdf,
              tooltip: 'Download / Open PDF',
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: buildPlatformPdfView(pdfUrl: widget.pdfUrl),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PointerInterceptor(
                  child: DraggableAiFab(
                    onPressed: () => _openAiAssistantSheet(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_localFilePath != null)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
        ],
      ),
      body: Stack(
        children: [
          _isDownloading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(value: _downloadProgress),
                      const SizedBox(height: 16),
                      Text('Downloading PDF: ${(_downloadProgress * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                )
              : _localFilePath != null
                  ? PDFView(filePath: _localFilePath!)
                  : Center(
                      child: ElevatedButton.icon(
                        onPressed: _downloadPdf,
                        icon: const Icon(Icons.download),
                        label: const Text('Download and Open PDF'),
                      ),
                    ),
          
          DraggableAiFab(
            onPressed: () => _openAiAssistantSheet(context),
          ),
        ],
      ),
    );
  }
}