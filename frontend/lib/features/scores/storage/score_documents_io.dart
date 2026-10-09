import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:score/features/scores/storage/score_documents.dart';

Future<ScoreDocuments> openScoreDocuments() async {
  final directory = Directory(
    p.join((await getApplicationSupportDirectory()).path, 'scores'),
  );
  await directory.create(recursive: true);
  return FileScoreDocuments(directory: directory);
}

class FileScoreDocuments({
  required final Directory directory,
}) implements ScoreDocuments {
  File _file(String scoreId) {
    return File(p.join(directory.path, scoreDocumentName(scoreId)));
  }

  @override
  Future<String?> read(String scoreId) async {
    final file = _file(scoreId);
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String scoreId, String musicXml) async {
    final file = _file(scoreId);
    final writing = File('${file.path}.writing');
    await writing.writeAsString(musicXml, flush: true);
    await writing.rename(file.path);
  }

  @override
  Future<void> remove(String scoreId) async {
    final file = _file(scoreId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<List<String>> ids() async {
    final ids = <String>[];
    await for (final entry in directory.list()) {
      if (entry is! File) continue;
      final id = scoreIdOfDocument(p.basename(entry.path));
      if (id != null) ids.add(id);
    }
    return ids;
  }
}
