import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:score/notation/musicxml/model.dart';
import 'package:score/notation/musicxml/parser.dart';
import 'package:score/notation/view/musicxml_view.dart';
import 'package:score/notation/view/score_view.dart';

/// The reader, asked to read the real thing.
///
/// The two files are the ones the API's own tests are written against: a
/// Beethoven song and a Brahms one, both of them written by a real engraver
/// and both carrying most of what a score carries — several voices to a staff,
/// chords, beams, slurs, ties, lyrics, wedges, a pickup bar.

/// Where the repository keeps the scores its own tests are written against.
const _examples = '../test/example_data';

String _read(String name) => File('$_examples/$name').readAsStringSync();

void main() {
  test('the example scores are on disk where this expects them', () {
    expect(Directory(_examples).existsSync(), isTrue,
        reason: 'run this from the frontend_flutter directory');
  });

  group('Beethoven', () {
    late MusicXmlScore score;

    setUpAll(() => score = parseMusicXml(_read('BeetAnGeSample.musicxml')));

    test('it is read as a score with a name and a composer', () {
      expect(score.title, isNotEmpty);
      expect(score.title, isNot('Untitled score'));
      expect(score.creators, isNotEmpty);
    });

    test('every part it declares is a part that is played', () {
      expect(score.parts, isNotEmpty);
      for (final part in score.parts) {
        expect(part.measures, isNotEmpty, reason: 'part ${part.id}');
      }
    });

    test('the notes are read with a pitch, a length and a voice', () {
      final notes = score.parts
          .expand((part) => part.measures)
          .expand((measure) => measure.notes)
          .toList();

      expect(notes.length, greaterThan(200));
      expect(notes.where((note) => note.pitch != null), isNotEmpty);
      expect(notes.where((note) => note.isRest), isNotEmpty);
      expect(notes.where((note) => note.isChord), isNotEmpty);

      // Everything says how long it is drawn except a rest that lasts the whole
      // bar, which is drawn the same way whatever the bar is worth — and this
      // score has exactly one of those.
      expect(notes.where((note) => note.type == null && !note.isMeasureRest),
          isEmpty);
      expect(notes.where((note) => note.isMeasureRest), isNotEmpty);
    });

    test('what a bar is written in is read', () {
      final attributes = score.parts.first.measures
          .expand((measure) => measure.items)
          .whereType<Attributes>()
          .toList();

      expect(attributes, isNotEmpty);
      expect(attributes.first.divisions, isNotNull);
      expect(attributes.expand((a) => a.clefs), isNotEmpty);
      expect(attributes.expand((a) => a.times), isNotEmpty);
    });

    test('the words are read, and know which verse they are', () {
      final lyrics = score.parts
          .expand((part) => part.measures)
          .expand((measure) => measure.notes)
          .expand((note) => note.lyrics)
          .toList();

      expect(lyrics, isNotEmpty);
      expect(lyrics.every((lyric) => lyric.number >= 1), isTrue);
    });

    test('a second voice on a staff is written by winding the clock back', () {
      final backups = score.parts
          .expand((part) => part.measures)
          .expand((measure) => measure.items)
          .whereType<Backup>()
          .toList();

      expect(backups, isNotEmpty);
      expect(backups.every((backup) => backup.duration > 0), isTrue);
    });
  });

  group('Brahms', () {
    late MusicXmlScore score;

    setUpAll(() => score = parseMusicXml(_read('BrahWiMeSample.musicxml')));

    test('it is read whole', () {
      expect(score.parts, isNotEmpty);
      expect(
        score.parts.expand((part) => part.measures).expand((m) => m.notes).length,
        greaterThan(150),
      );
    });

    test('ties and slurs are read off the notes that carry them', () {
      final notes = score.parts
          .expand((part) => part.measures)
          .expand((measure) => measure.notes)
          .toList();

      expect(notes.where((note) => note.notations.tieStarts), isNotEmpty);
      expect(notes.where((note) => note.notations.tieStops), isNotEmpty);
      expect(notes.where((note) => note.notations.slurs.isNotEmpty), isNotEmpty);
    });

    test('beams say where they begin and end', () {
      final beamed = score.parts
          .expand((part) => part.measures)
          .expand((measure) => measure.notes)
          .where((note) => note.beams.isNotEmpty)
          .toList();

      expect(beamed, isNotEmpty);
      expect(beamed.any((note) => note.beams[1] == 'begin'), isTrue);
      expect(beamed.any((note) => note.beams[1] == 'end'), isTrue);
    });
  });

  group('a score read the way it is being looked at', () {
    test('a view that changes nothing hands back the very file it was given', () {
      final source = _read('BrahWiMeSample.musicxml');
      final parts = parseMusicXml(source).parts.map((part) => part.id).toList();

      expect(musicXmlForView(source, ScoreView.forParts(parts)), source);
    });

    test('a transposed score is still a score, and it has moved', () {
      final source = _read('BrahWiMeSample.musicxml');
      final written = parseMusicXml(source);
      final view = ScoreView.forParts(
        written.parts.map((part) => part.id).toList(),
      ).withTransposition(3);

      final moved = parseMusicXml(musicXmlForView(source, view));

      // The same music, note for note, three semitones along.
      final before = _pitches(written);
      final after = _pitches(moved);
      expect(after.length, before.length);
      for (var i = 0; i < before.length; i++) {
        expect(after[i] - before[i], 3, reason: 'note $i');
      }
    });

    test('a part taken off the screen is taken out of the file', () {
      final source = _read('BeetAnGeSample.musicxml');
      final written = parseMusicXml(source);
      final parts = written.parts.map((part) => part.id).toList();
      expect(parts.length, greaterThan(1),
          reason: 'this needs a score of more than one part');

      final view = ScoreView.forParts(parts).withPartVisible(parts.first, false);
      final shown = parseMusicXml(musicXmlForView(source, view));

      expect(shown.parts.map((part) => part.id), isNot(contains(parts.first)));
      expect(shown.parts.length, parts.length - 1);
    });
  });
}

/// What every note of a score sounds like, in semitones from C0, in the order
/// they are written.
List<double> _pitches(MusicXmlScore score) => [
      for (final part in score.parts)
        for (final measure in part.measures)
          for (final note in measure.notes)
            if (note.pitch != null)
              const [0, 2, 4, 5, 7, 9, 11][
                      'CDEFGAB'.indexOf(note.pitch!.step)] +
                  note.pitch!.alter +
                  12 * note.pitch!.octave,
    ];
