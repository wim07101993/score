@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/scores/storage/score_documents_io.dart';

/// The documents of the scores, kept as files on a device.

void main() {
  late Directory directory;
  late FileScoreDocuments documents;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('score_documents');
    addTearDown(() => directory.delete(recursive: true));
    documents = FileScoreDocuments(directory: directory);
  });

  test(
    'a document that is written is read back, as a file of its own',
    () async {
      await documents.write('abc', '<score-partwise/>');

      expect(await documents.read('abc'), '<score-partwise/>');
      expect(File('${directory.path}/abc.musicxml').existsSync(), isTrue);
    },
  );

  test('one that is not here is nothing, not an error', () async {
    expect(await documents.read('nothing'), isNull);
    await documents.remove('nothing');
  });

  test(
    'written again, it is the new one, and nothing is left half-way',
    () async {
      await documents.write('abc', '<old/>');
      await documents.write('abc', '<new/>');

      expect(await documents.read('abc'), '<new/>');
      expect(directory.listSync().map((entry) => entry.uri.pathSegments.last), [
        'abc.musicxml',
      ]);
    },
  );

  test('the scores it holds are listed by their ids', () async {
    // Half-written ones, left by an app that was stopped, are not a score's.
    await documents.write('abc', '<score-partwise/>');
    await documents.write('a/b c', '<score-partwise/>');
    File('${directory.path}/def.musicxml.writing').writeAsStringSync('<');

    expect(await documents.ids(), unorderedEquals(['abc', 'a/b c']));
  });

  test('forgotten, it is gone', () async {
    await documents.write('abc', '<score-partwise/>');
    await documents.remove('abc');

    expect(await documents.read('abc'), isNull);
    expect(directory.listSync(), isEmpty);
  });

  test('an id that is not a file name stays in the directory', () async {
    await documents.write('../escape', '<score-partwise/>');

    expect(await documents.read('../escape'), '<score-partwise/>');
    expect(
      directory.parent.listSync().whereType<File>().where(
        (file) => file.path.endsWith('.musicxml'),
      ),
      isEmpty,
    );
    expect(directory.listSync(), hasLength(1));
  });
}
