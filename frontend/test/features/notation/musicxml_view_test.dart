import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:score/features/notation/parts.dart';
import 'package:score/features/notation/view/musicxml_view.dart';
import 'package:score/features/notation/view/score_view.dart';

/// Downloading what is on the screen.
///
/// A view is something that happens on the way to the screen, and the document
/// the app holds is the one that was uploaded. These are about the one place
/// that stops being true: the download button, where a player wants the score
/// in the key they are reading it in and without the fifteen staves they are
/// not playing.

const _examples = '../test/example_data';

String _read(String name) => File('$_examples/$name').readAsStringSync();

void main() {
  final musicXml = _read('BeetAnGeSample.musicxml');
  final parts = readParts(parseMusicXml(musicXml));
  final pristine = ScoreView.forParts([for (final part in parts) part.id]);

  test('a score nobody has touched is the file that was uploaded', () {
    // Byte for byte, not "the same music": an editor who uploaded a file and
    // downloaded it again should get their own file back, not a round trip
    // through somebody's model.
    expect(musicXmlForView(musicXml, pristine), same(musicXml));
    expect(musicXmlForView(musicXml, null), same(musicXml));
  });

  test('a transposed score comes out transposed, and can be read back', () {
    final written = musicXmlForView(musicXml, pristine.withTransposition(3));

    expect(written, isNot(musicXml));
    // The point of the round trip: what comes out is a score again, not just
    // text that looks like one.
    expect(readParts(parseMusicXml(written)).length, parts.length);
  });

  test('a hidden part is not in the file either', () {
    expect(parts.length, greaterThan(1));
    final written = musicXmlForView(
      musicXml,
      pristine.withPartVisible(parts.first.id, false),
    );

    expect(readParts(parseMusicXml(written)).length, parts.length - 1);
  });

  test('hiding every part is refused rather than written out empty', () {
    // The view itself refuses it, so nothing here has to: a file with no parts
    // in it is not a score anybody can open.
    var view = pristine;
    for (final part in parts) {
      view = view.withPartVisible(part.id, false);
    }

    expect(view.visiblePartIds, isNotEmpty);
    expect(readParts(parseMusicXml(musicXmlForView(musicXml, view))),
        isNotEmpty);
  });
}
