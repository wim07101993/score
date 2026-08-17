import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Handing a file to a browser, which is done by making a link to it out of
/// thin air and clicking it. There is no other way in: a page cannot write to
/// the machine it is on, and it is not supposed to be able to.
Future<bool> savePlatformFile({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);

  final link = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  web.document.body!.append(link);
  link.click();
  link.remove();

  // The blob stays in memory until it is let go of, and a score is not small.
  web.URL.revokeObjectURL(url);
  return true;
}
