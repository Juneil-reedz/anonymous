// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveImageOnWeb(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  // Opens image in new tab — on iPhone Safari: tap Share → Save to Photos
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);
}

Future<bool> shareImageOnWeb(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  // Try Web Share API (works on iOS Safari)
  final nav = html.window.navigator;
  try {
    await nav.share({'url': url, 'title': 'Anonymous Card'});
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (_) {}
  // Fallback: open in new tab
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);
  return true;
}
