@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/scores/storage/score_documents_web.dart';

/// The documents of the scores, kept as files in the browser's origin private
/// file system — run with `flutter test --platform chrome`.

void main() {
  test('a document that is written is read back, and forgotten', () async {
    final documents = await openScoreDocuments();
    await documents.remove('abc');

    expect(await documents.read('abc'), isNull);
    expect(await documents.read('abc'), isNull);

    await documents.write('abc', '<old/>');
    await documents.write('abc', '<new/>');
    expect(await documents.read('abc'), '<new/>');
    expect(await documents.read('abc'), isNotNull);

    // Opened again, as the next start of the app does.
    expect(await (await openScoreDocuments()).read('abc'), '<new/>');

    await documents.remove('abc');
    expect(await documents.read('abc'), isNull);
  });
}
