import 'dart:typed_data';

import 'file_saver_native.dart'
    if (dart.library.js_interop) 'file_saver_web.dart';

/// Writing a file out of the app and into wherever the user keeps things.
///
/// A browser has no filesystem to write to, so it hands the bytes to the
/// browser and lets it do what it does with a download; a device asks the user
/// where to put it. Both end with a file the user has, which is all the caller
/// cares about.
///
/// Hands back `false` when the user changed their mind, which is not a failure
/// and should not be reported as one.
Future<bool> saveFile({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) =>
    savePlatformFile(filename: filename, bytes: bytes, mimeType: mimeType);
