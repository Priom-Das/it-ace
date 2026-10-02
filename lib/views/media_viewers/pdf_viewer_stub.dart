// File: lib/views/media_viewers/pdf_viewer_stub.dart

import 'package:flutter/material.dart';

/// Provides a fallback view for non-web platforms such as Android and iOS.
Widget buildPlatformPdfView({required String pdfUrl}) {
  return const Scaffold(
    body: Center(
      child: Text('PDF viewer web implementation is not available on this platform.'),
    ),
  );
}