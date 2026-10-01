import 'dart:io';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../ai_assistant/draggable_ai_fab.dart';

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
  String? _viewId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initWebObjectPdfViewer();
    } else {
      _checkAndAutoDownloadPdf();
    }
  }

  // English Comment: Uses HTML Object element for robust web PDF rendering without external Google dependency.
  void _initWebObjectPdfViewer() {
    try {
      _viewId = 'pdf-object-${DateTime.now().millisecondsSinceEpoch}';

      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId!,
        (int id) => html.ObjectElement()
          ..data = widget.pdfUrl
          ..type = 'application/pdf'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%',
      );
      
      setState(() {
        _isDownloading = false;
      });
    } catch (e) {
      debugPrint('Web object viewer init error: $e');
      setState(() {
        _isDownloading = false;
      });
    }
  }

  // English Comment: Automatically checks local storage or triggers download immediately for mobile view.
  Future<void> _checkAndAutoDownloadPdf() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = widget.pdfUrl.split('/').last.split('?').first;
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
      final fileName = widget.pdfUrl.split('/').last.split('?').first;
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
            _isDownloading
                ? const Center(child: CircularProgressIndicator())
                : _viewId == null
                    ? const Center(child: Text('Failed to load PDF view.'))
                    : Positioned.fill(
                        child: HtmlElementView(viewType: _viewId!),
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