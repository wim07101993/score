import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Asking the user where to put a file, and putting it there.
///
/// The picker writes the bytes itself, on a phone and on a desktop alike, and
/// hands back where it put them. So what comes back is a file the user chose
/// the place of, already written, or nothing because they changed their mind.
Future<bool> savePlatformFile({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final path = await FilePicker.saveFile(
    fileName: filename,
    bytes: bytes,
  );
  return path != null;
}
