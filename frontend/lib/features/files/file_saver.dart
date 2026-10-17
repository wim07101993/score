import 'dart:typed_data';

import 'package:score/features/files/file_saver_native.dart'
    if (dart.library.js_interop) 'package:score/features/files/file_saver_web.dart';

Future<bool> saveFile({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) => savePlatformFile(filename: filename, bytes: bytes, mimeType: mimeType);
