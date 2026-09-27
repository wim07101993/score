import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Asking the user where to put a file, and putting it there.
///
/// On a phone the picker writes the bytes itself; on a desktop it hands back a
/// path to write to. Either way what comes back is a file the user chose the
/// place of, or nothing because they changed their mind.
Future<bool> savePlatformFile({
  required String filename,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final path = await FilePicker.saveFile(
    fileName: filename,
    bytes: bytes,
  );
  if (path == null) {
    return false;
  }

  // Android and iOS write it themselves and hand back where they put it;
  // writing again there would be writing over the file with itself.
  if (Platform.isAndroid || Platform.isIOS) {
    return true;
  }

  await File(path).writeAsBytes(bytes, flush: true);
  return true;
}
