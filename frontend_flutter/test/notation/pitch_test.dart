import 'package:flutter_test/flutter_test.dart';
import 'package:score/notation/view/pitch.dart';

/// The tests the JavaScript renderer was held to, asked of the Dart one.
///
/// The music is the same music, so these are a port rather than a rewrite: if
/// the two ever disagree about what a transposed score is spelled like, it is
/// this file that says so.

/// Every key a score is likely to be written in, and a few it is not.
const keys = [-7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7];

/// Every distance the app lets a score be transposed by.
const distances = [
  -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, //
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
];

/// A note as it is written, such as "Eb4" or "F#3".
Pitch pitch(String spelled) {
  final match = RegExp(r'^([A-G])(b*|#*)(-?\d+)$').firstMatch(spelled)!;
  final accidental = match.group(2)!;
  return Pitch(
    match.group(1)!,
    accidental.startsWith('b')
        ? -accidental.length.toDouble()
        : accidental.length.toDouble(),
    int.parse(match.group(3)!),
  );
}

String spell(Pitch moved) {
  final alter = moved.alter.round();
  final accidental = alter < 0 ? 'b' * -alter : '#' * alter;
  return '${moved.step}$accidental${moved.octave}';
}

/// What a written note sounds like, counted in semitones from C0.
double sounds(String spelled) {
  final note = pitch(spelled);
  return stepSemitones['CDEFGAB'.indexOf(note.step)] +
      note.alter +
      12 * note.octave;
}

/// Transposes a note the way a score in [fifths] would be transposed.
String transposed(String spelled, int semitones, [int fifths = 0]) {
  return spell(transposePitch(pitch(spelled), intervalFor(semitones, fifths))!);
}

/// The key a score in [fifths] lands in when it is moved [semitones].
num movedKey(int fifths, int semitones) =>
    transposeFifths(fifths, intervalFor(semitones, fifths));

void main() {
  // -------------------------------------------------------------------------
  // THE INTERVAL A SCORE MOVES BY
  // -------------------------------------------------------------------------

  test('a distance in semitones is a distance in letters as well', () {
    // A third is written as a third whether it is major or minor, which is why
    // three and four semitones both move two letters.
    final letters = [for (var s = 0; s <= 12; s++) intervalFor(s, 0).steps];

    expect(letters, [0, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 6, 7]);
  });

  test('going down moves as far as going up', () {
    for (final semitones in distances.where((d) => d != 0)) {
      expect(intervalFor(-semitones, 0).steps, -intervalFor(semitones, 0).steps,
          reason: '$semitones semitones');
    }
  });

  test('an interval carries the distance it was asked for', () {
    for (final fifths in keys) {
      for (final semitones in distances) {
        expect(intervalFor(semitones, fifths).semitones, semitones);
      }
    }
  });

  test('an interval is never more than a semitone or so off the plain one', () {
    // An interval is diminished, minor, major or augmented, and nothing further
    // out than that. A doubly augmented fourth is a sign the letter went the
    // wrong way, which is the failure this is here to catch.
    const plain = [0, 2, 4, 5, 7, 9, 11];

    for (final fifths in keys) {
      for (final semitones in distances) {
        final steps = intervalFor(semitones, fifths).steps;
        final between = plain[steps % 7] + 12 * (steps / 7).floor();
        expect((semitones - between).abs() <= 2, isTrue,
            reason: '$semitones semitones in $fifths came out as $steps letters');
      }
    }
  });

  // -------------------------------------------------------------------------
  // THE KEY IT IS WRITTEN IN
  // -------------------------------------------------------------------------

  test('a key moves round the circle of fifths', () {
    expect(movedKey(0, 2), 2, reason: 'D has two sharps');
    expect(movedKey(0, 5), -1, reason: 'F has one flat');
    expect(movedKey(0, 7), 1, reason: 'G has one sharp');
    expect(movedKey(0, -2), -2, reason: 'Bb has two flats');
    expect(movedKey(0, -5), 1, reason: 'G has one sharp');
  });

  test('a key is written whichever way round is easier to read', () {
    // Up a semitone from C is Db with five flats, not C# with seven sharps.
    expect(movedKey(0, 1), -5);
    // Down a semitone is B with five sharps, not Cb with seven flats.
    expect(movedKey(0, -1), 5);
  });

  test('a key that is already a long way round comes back', () {
    expect(movedKey(7, 1), 2, reason: 'C# up a semitone is D');
    expect(movedKey(-7, -1), -2, reason: 'Cb down a semitone is Bb');
  });

  test('a key transposed by an octave is the key it was', () {
    for (final fifths in keys) {
      expect(movedKey(fifths, 12), fifths);
      expect(movedKey(fifths, -12), fifths);
    }
  });

  test('a key is never left somewhere a key signature cannot be written', () {
    // Seven sharps or seven flats is every letter of the scale altered once,
    // and there is no such thing as an eighth. A transposition that lands past
    // it has to be spelled its other way instead.
    for (final fifths in keys) {
      for (final semitones in distances) {
        final moved = movedKey(fifths, semitones);
        expect(moved.abs() <= 7, isTrue,
            reason: '$fifths moved by $semitones came out at $moved');
      }
    }
  });

  test('a key too far round the circle is spelled the other way instead', () {
    // Down a tritone from Bb, read plainly, is a diminished fifth to Fb major:
    // eight flats, which is not a key signature. It is E major with four sharps.
    expect(movedKey(-2, -6), 4);
    // And up a tritone from C# is F## major before it is G major.
    expect(movedKey(7, 6), 1);
  });

  // -------------------------------------------------------------------------
  // THE NOTES
  // -------------------------------------------------------------------------

  test('a note keeps the interval it was written at', () {
    // A minor third up is a third: two letters, however the accidental lands.
    expect(transposed('C4', 3), 'Eb4');
    expect(transposed('D4', 3), 'F4');
    expect(transposed('E4', 3), 'G4');

    // A major second up is a second, never a third.
    expect(transposed('C4', 2), 'D4');
    expect(transposed('Bb3', 2), 'C4');
  });

  test('a sharp stays a sharp rather than turning into the letter above it', () {
    // The one that gives a naive transposer away: D# up a minor third is F#,
    // because a third from D is an F. Reaching for whichever letter sits
    // nearest the new sound would give G, and a player reading a D#-F#-A# chord
    // would be handed one spelled D#-G-A#.
    expect(transposed('D#4', 3), 'F#4');
    expect(transposed('F#4', 3), 'A4');
    expect(transposed('A#4', 3), 'C#5');
  });

  test('a note carries into the next octave when it runs off the end', () {
    expect(transposed('B4', 1), 'C5');
    expect(transposed('A4', 3), 'C5');
    expect(transposed('C4', -1), 'B3');
    expect(transposed('C4', -12), 'C3');
    expect(transposed('C0', -1), 'B-1');
  });

  test('a note transposed an octave is the note it was, an octave along', () {
    for (final spelled in ['C4', 'Eb3', 'F#5', 'Bb2', 'A#4']) {
      final octave = int.parse(RegExp(r'-?\d+$').firstMatch(spelled)!.group(0)!);
      final body = spelled.substring(0, spelled.length - '$octave'.length);
      expect(transposed(spelled, 12), '$body${octave + 1}');
      expect(transposed(spelled, -12), '$body${octave - 1}');
    }
  });

  test('a note transposed by nothing is the note it was', () {
    for (final spelled in ['C4', 'Eb3', 'F#5', 'B4', 'Cb4']) {
      expect(transposed(spelled, 0), spelled);
    }
  });

  test('a note keeps its distance from every other note', () {
    // Whatever the spelling comes out as, the sound has to move by exactly what
    // was asked for. This is the half of it the spelling tests cannot see.
    for (final fifths in keys) {
      for (final spelled in ['C4', 'D#4', 'Eb3', 'F#5', 'B4', 'Cb4', 'A#2']) {
        for (final semitones in distances) {
          expect(
            sounds(transposed(spelled, semitones, fifths)) - sounds(spelled),
            semitones,
            reason: '$spelled moved by $semitones in $fifths',
          );
        }
      }
    }
  });

  test('something that is not a note is refused rather than misread', () {
    // Where the JavaScript hands back the very object it was given, this hands
    // back nothing at all: both are a caller's cue that there was nothing here
    // it could read, and without one the unreadable value would be written back
    // into the score as the word NaN.
    final interval = intervalFor(3, 0);

    for (final notANote in [
      const Pitch('H', 0, 4),
      const Pitch('', 0, 4),
      Pitch('C', double.nan, 4),
      Pitch('C', double.infinity, 4),
    ]) {
      expect(transposePitch(notANote, interval), isNull, reason: '$notANote');
    }
  });

  test('a note this can read is never refused', () {
    // The other half of it: a caller telling the two apart would quietly stop
    // transposing anything if a real note ever came back as nothing.
    for (final semitones in distances) {
      expect(transposePitch(const Pitch('C', 0, 4), intervalFor(semitones, 0)),
          isNotNull);
    }
  });

  // -------------------------------------------------------------------------
  // THE TWO OF THEM TOGETHER
  // -------------------------------------------------------------------------

  /// How a letter is written in a given key: the sharps of a key signature are
  /// added in the order F C G D A E B and the flats in the reverse of it, so
  /// how many the signature has says which letters they land on.
  int alterInKey(String step, num fifths) {
    final sharps = 'FCGDAEB'.indexOf(step);
    final flats = 'BEADGCF'.indexOf(step);
    if (fifths > 0) {
      return sharps < fifths ? 1 : 0;
    }
    return flats < -fifths ? -1 : 0;
  }

  test('the scale of a key transposes into the scale of the key it lands in', () {
    // The strongest thing there is to say about a transposition: play the scale
    // of the key the score is in, transpose it, and what comes out has to be
    // the scale of the key the score is now in — the same seven notes the new
    // key signature describes, spelled the way it spells them. Nothing in a
    // score can be right if this is wrong, and it is checked in every key at
    // every distance the app allows.
    for (final fifths in keys) {
      for (final semitones in distances) {
        final interval = intervalFor(semitones, fifths);
        final key = transposeFifths(fifths, interval);

        for (final step in 'CDEFGAB'.split('')) {
          final written =
              Pitch(step, alterInKey(step, fifths).toDouble(), 4);
          final moved = transposePitch(written, interval)!;

          expect(
            moved.alter,
            alterInKey(moved.step, key),
            reason: '${spell(written)} in $fifths moved by $semitones'
                ' came out as ${spell(moved)}, which is not in $key',
          );
        }
      }
    }
  });

  test('the tritone takes the key and the notes the same way', () {
    // There is no right answer to six semitones, only a convention, and the
    // only thing that would be wrong is the key going one way and the notes the
    // other.
    expect(transposed('C4', 6), 'F#4');
    expect(movedKey(0, 6), 6, reason: 'six sharps going up');

    expect(transposed('C4', -6), 'Gb3');
    expect(movedKey(0, -6), -6, reason: 'six flats coming down');

    // And where the key had to be spelled the other way, the notes go with it:
    // a score in Bb goes down a tritone to E, so its Bb is an E and not an Fb.
    expect(transposed('Bb4', -6, -2), 'E4');
  });
}
