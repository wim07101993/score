import 'dart:async';
import 'dart:convert';

import 'package:behaviour/behaviour.dart';
import 'package:file_picker/file_picker.dart';

class PickMusicXmlFile({
  required super.monitor,
}) extends BehaviourWithoutInput<String?> {
  @override
  String get description => 'picking musicxml file';

  @override
  FutureOr<String?> action(BehaviourTrack? track) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['musicxml', 'xml'],
    );
    final file = picked.firstOrNull;
    if (file == null) {
      return null;
    }
    final bytes = await file.readAsBytes();
    return utf8.decode(bytes);
  }
}
