import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<Uint8List?> pickImageWeb() async {
  final raw = await _pickRaw();
  if (raw == null) return null;
  return _resizeToJpeg(raw);
}

// Step 1: open file picker and read raw bytes
Future<Uint8List?> _pickRaw() async {
  final completer = Completer<Uint8List?>();
  final input = web.HTMLInputElement();
  input.type = 'file';
  input.accept = 'image/*';
  // iOS Safari blocks .click() on display:none — position offscreen instead
  input.style.setProperty('position', 'fixed');
  input.style.setProperty('top', '-9999px');
  input.style.setProperty('left', '-9999px');
  input.style.setProperty('opacity', '0');
  web.document.body!.append(input);

  bool done = false;

  input.addEventListener('change', ((web.Event _) {
    if (done) return;
    done = true;
    final files = input.files;
    if (files == null || files.length == 0) {
      completer.complete(null);
      input.remove();
      return;
    }
    final reader = web.FileReader();
    reader.addEventListener('load', ((web.Event _) {
      final buf = (reader.result as JSArrayBuffer).toDart;
      completer.complete(Uint8List.view(buf));
      input.remove();
    }).toJS);
    reader.addEventListener('error', ((web.Event _) {
      completer.complete(null);
      input.remove();
    }).toJS);
    reader.readAsArrayBuffer(files.item(0)!);
  }).toJS);

  input.addEventListener('cancel', ((web.Event _) {
    if (!done) { done = true; completer.complete(null); input.remove(); }
  }).toJS);

  input.click();
  return completer.future;
}

// Step 2: resize to max 400×400 JPEG via canvas (keeps image small for upload)
Future<Uint8List?> _resizeToJpeg(Uint8List raw, {int maxDim = 400}) async {
  final completer = Completer<Uint8List?>();

  final blob = web.Blob(<JSAny>[raw.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  final img = web.HTMLImageElement();

  img.addEventListener('load', ((web.Event _) {
    final iw = img.naturalWidth;
    final ih = img.naturalHeight;

    int dw = iw, dh = ih;
    if (iw > maxDim || ih > maxDim) {
      if (iw >= ih) {
        dw = maxDim;
        dh = (ih * maxDim / iw).round();
      } else {
        dh = maxDim;
        dw = (iw * maxDim / ih).round();
      }
    }

    final canvas = web.HTMLCanvasElement()
      ..width = dw
      ..height = dh;

    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    ctx.drawImage(img, 0, 0, dw, dh);
    web.URL.revokeObjectURL(url);

    // toDataURL returns "data:image/jpeg;base64,<data>"
    final dataUrl = canvas.toDataURL('image/jpeg', (0.82).toJS);
    try {
      completer.complete(base64Decode(dataUrl.split(',').last));
    } catch (_) {
      completer.complete(null);
    }
  }).toJS);

  img.addEventListener('error', ((web.Event _) {
    web.URL.revokeObjectURL(url);
    completer.complete(null);
  }).toJS);

  img.src = url;
  return completer.future;
}
