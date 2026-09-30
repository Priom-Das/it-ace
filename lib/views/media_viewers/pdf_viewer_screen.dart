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

// English Comment: PDF Viewer Screen supporting iframe rendering on Web with PointerInterceptor and modern Draggable AI FAB on Mobile.
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
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _viewId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _viewId = 'pdf-iframe-${DateTime.now().millisecondsSinceEpoch}';
      // English Comment: Register iframe view factory for web PDF rendering
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId!,
        (int id) => html.IFrameElement()
          ..src = widget.pdfUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%',
      );
    } else {
      _checkExistingPdf();
    }
  }

  Future<void> _checkExistingPdf() async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = widget.pdfUrl.split('/').last;
    final file = File('${dir.path}/$fileName');

    if (await file.exists()) {
      setState(() {
        _localFilePath = file.path;
      });
    }
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = widget.pdfUrl.split('/').last;
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded successfully for offline view!')),
        );
      }
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
        appBar: AppBar(title: Text(widget.title)),
        body: Stack(
          children: [
            _viewId == null
                ? const Center(child: CircularProgressIndicator())
                : Positioned.fill(
                    child: HtmlElementView(viewType: _viewId!),
                  ),
            
            // English Comment: Ensure Draggable AI Floating Button is wrapped properly with PointerInterceptor on Web
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
          if (_localFilePath == null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _isDownloading ? null : _downloadPdf,
              tooltip: 'Download PDF for Offline',
            )
          else
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
                  : const Center(
                      child: Text('Click the download button top right to save and view offline.'),
                    ),
          
          // English Comment: Draggable AI Floating Button for Mobile
          DraggableAiFab(
            onPressed: () => _openAiAssistantSheet(context),
          ),
        ],
      ),
    );
  }
}