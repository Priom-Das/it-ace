// File: lib/views/media_viewers/pdf_viewer_web.dart

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildPlatformPdfView({required String pdfUrl}) {
  final String viewType = 'pdf-view-${pdfUrl.hashCode}';

  // Register the view factory for web
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int id) => html.ObjectElement()
      ..data = pdfUrl
      ..style.width = '100%'
      ..style.height = '100%',
  );

  return Scaffold(
    body: HtmlElementView(viewType: viewType),
  );
}