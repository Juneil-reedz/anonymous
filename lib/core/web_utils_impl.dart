// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:typed_data';

Future<void> saveImageOnWeb(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  // Open in new tab — on iPhone: long-press image → Save to Photos
  html.window.open(url, '_blank');
  Future.delayed(const Duration(seconds: 3), () => html.Url.revokeObjectUrl(url));
}

Future<bool> shareImageOnWeb(Uint8List bytes, String filename) async {
  try {
    // Build a JS File object from the image bytes
    final blob = html.Blob([bytes], 'image/png');
    final jsFile = js.JsObject(js.context['File'], [
      js.JsArray()..add(blob),
      filename,
      js.JsObject.jsify({'type': 'image/png'}),
    ]);

    final nav = js.context['navigator'];
    if (nav.hasProperty('canShare')) {
      // Build share data with the image file
      final shareData = js.JsObject(js.context['Object']);
      shareData['title'] = 'Anonymous Card';
      final filesArr = js.JsArray();
      filesArr.add(jsFile);
      shareData['files'] = filesArr;

      if (nav.callMethod('canShare', [shareData]) == true) {
        // Triggers the native iOS share sheet — user picks Facebook → Story
        nav.callMethod('share', [shareData]);
        return true;
      }
    }
  } catch (_) {}

  // Fallback: open image in new tab
  await saveImageOnWeb(bytes, filename);
  return true;
}
