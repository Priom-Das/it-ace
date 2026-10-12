// English Comment: Opens a web link. On Android / iOS it opens inside the app (Custom Tab / Safari view);
// on the web it opens a new browser tab because a normal page cannot show other sites inside itself.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openLink(BuildContext context, String url) async {
  final uri = Uri.parse(url); // non-ASCII characters in the path are percent-encoded by Uri
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!opened) opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
  }
}