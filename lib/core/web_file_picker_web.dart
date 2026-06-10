import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<Uint8List?> pickImageWeb() async {
  final completer = Completer<Uint8List?>();

  final input = web.HTMLInputElement();
  input.type = 'file';
  input.accept = 'image/*';
  // iOS Safari blocks .click() on display:none inputs — position offscreen instead
  input.style.setProperty('position', 'fixed');
  input.style.setProperty('top', '-9999px');
  input.style.setProperty('left', '-9999px');
  input.style.setProperty('opacity', '0');

  web.document.body!.append(input);

  bool done = false;

  input.addEventListener(
    'change',
    ((web.Event _) {
      if (done) return;
      done = true;
      final files = input.files;
      if (files == null || files.length == 0) {
        completer.complete(null);
        input.remove();
        return;
      }
      final file = files.item(0)!;
      final reader = web.FileReader();
      reader.addEventListener(
        'load',
        ((web.Event _) {
          final buf = (reader.result as JSArrayBuffer).toDart;
          completer.complete(Uint8List.view(buf));
          input.remove();
        }).toJS,
      );
      reader.addEventListener(
        'error',
        ((web.Event _) {
          completer.complete(null);
          input.remove();
        }).toJS,
      );
      reader.readAsArrayBuffer(file);
    }).toJS,
  );

  input.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!done) {
        done = true;
        completer.complete(null);
        input.remove();
      }
    }).toJS,
  );

  input.click();
  return completer.future;
}
