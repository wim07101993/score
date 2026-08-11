import 'package:flutter_test/flutter_test.dart';
import 'package:score/notation/layout/staff_position.dart';
import 'package:score/notation/musicxml/model.dart';

/// Where a note goes on a staff.
///
/// Everything the renderer draws hangs off this, so it is checked against the
/// staff as a player reads it: the top line is 0, the bottom line is 4, and
/// every step of the scale is half a space.

const treble = Clef(sign: 'G', line: 2);
const bass = Clef(sign: 'F', line: 4);
const alto = Clef(sign: 'C', line: 3);
const tenor = Clef(sign: 'C', line: 4);
const trebleDown = Clef(sign: 'G', line: 2, octaveChange: -1);

void main() {
  group('a treble clef', () {
    test('puts the notes of the staff on its lines and spaces', () {
      // Bottom line up: E4 G4 B4 D5 F5, and the spaces between them.
      expect(staffY(treble, 'E', 4), 4.0, reason: 'bottom line');
      expect(staffY(treble, 'F', 4), 3.5);
      expect(staffY(treble, 'G', 4), 3.0, reason: 'the line the clef names');
      expect(staffY(treble, 'A', 4), 2.5);
      expect(staffY(treble, 'B', 4), 2.0, reason: 'middle line');
      expect(staffY(treble, 'C', 5), 1.5);
      expect(staffY(treble, 'D', 5), 1.0);
      expect(staffY(treble, 'E', 5), 0.5);
      expect(staffY(treble, 'F', 5), 0.0, reason: 'top line');
    });

    test('puts middle C one ledger line below the staff', () {
      expect(staffY(treble, 'C', 4), 5.0);
    });

    test('puts a note an octave along seven halves along', () {
      expect(staffY(treble, 'C', 5) - staffY(treble, 'C', 4), -3.5);
      expect(staffY(treble, 'C', 3) - staffY(treble, 'C', 4), 3.5);
    });

    test('does not care how a note is spelled, only what letter it is', () {
      // A C sharp and a C flat are both written where a C is written; the
      // accidental in front of it is what says which.
      expect(staffY(treble, 'C', 4), staffY(treble, 'c', 4));
    });
  });

  group('a bass clef', () {
    test('puts the notes of the staff on its lines and spaces', () {
      // Bottom line up: G2 B2 D3 F3 A3.
      expect(staffY(bass, 'G', 2), 4.0, reason: 'bottom line');
      expect(staffY(bass, 'A', 2), 3.5);
      expect(staffY(bass, 'B', 2), 3.0);
      expect(staffY(bass, 'D', 3), 2.0, reason: 'middle line');
      expect(staffY(bass, 'F', 3), 1.0, reason: 'the line the clef names');
      expect(staffY(bass, 'A', 3), 0.0, reason: 'top line');
    });

    test('puts middle C one ledger line above the staff', () {
      expect(staffY(bass, 'C', 4), -1.0);
    });
  });

  group('a C clef', () {
    test('puts middle C on the line it names', () {
      // The whole point of the clef: the third line in alto, the fourth in
      // tenor, and middle C on whichever it is.
      expect(staffY(alto, 'C', 4), 2.0);
      expect(staffY(tenor, 'C', 4), 1.0);
    });
  });

  test('a clef with an eight under it reads an octave along', () {
    // A tenor's or a guitarist's middle C is written where a pianist would
    // write the C above it.
    expect(staffY(trebleDown, 'C', 4), staffY(treble, 'C', 5));
    expect(staffY(trebleDown, 'E', 4), staffY(treble, 'E', 5));
  });

  group('a key signature', () {
    test('is written where it is written, in a treble clef', () {
      expect(keySignatureShift(treble), 0.0);
    });

    test('moves down two steps in a bass clef', () {
      // The first sharp is on the top line in treble and on the fourth line in
      // bass, which is two half-spaces down.
      expect(keySignatureShift(bass), 2.0);
    });

    test('moves by less than half an octave, whatever the clef', () {
      // A signature that moved further than that would be written off the
      // staff, which is the failure this is here to catch.
      for (final clef in [treble, bass, alto, tenor, trebleDown]) {
        expect(keySignatureShift(clef).abs(), lessThanOrEqualTo(3.0),
            reason: '${clef.sign}${clef.effectiveLine}');
      }
    });

    test('lands on the staff in every clef', () {
      // A key signature is never written off the staff — there is nothing out
      // there for it to mean. The one thing allowed past the top line is a
      // sharp sitting half a space above it, which is where the third one goes
      // in a treble clef.
      for (final clef in [treble, bass, alto, tenor, trebleDown]) {
        for (final places in [trebleSharpPlaces, trebleFlatPlaces]) {
          for (final place in places) {
            final y = keySignaturePlace(place, clef) * 0.5;
            expect(y, inInclusiveRange(-0.5, 4.5),
                reason: 'accidental at $place in'
                    ' ${clef.sign}${clef.effectiveLine}');
          }
        }
      }
    });

    test('keeps the treble placement a treble clef reader knows', () {
      // The third sharp above the top line, the first on it, and the first flat
      // on the middle line's neighbour: moving any of these would be a change
      // to how every score in the app reads.
      expect(keySignaturePlace(trebleSharpPlaces[0], treble), 0.0);
      expect(keySignaturePlace(trebleSharpPlaces[2], treble), -1.0);
      expect(keySignaturePlace(trebleFlatPlaces[0], treble), 4.0);
    });

    test('writes an accidental an octave along rather than off the staff', () {
      // In a tenor clef the third sharp would otherwise be a full space above
      // the top line, which is not somewhere a key signature is ever written.
      expect(trebleSharpPlaces[2] + keySignatureShift(tenor), -2.0);
      expect(keySignaturePlace(trebleSharpPlaces[2], tenor), 5.0);
    });
  });

  group('a rest', () {
    test('sits in the middle of the staff when it says nothing', () {
      expect(noteY(const Note(duration: 1, rest: Rest(), type: 'quarter'), treble), 2.0);
    });

    test('hangs from the second line down when it lasts the whole bar', () {
      expect(
        noteY(const Note(duration: 1, rest: Rest(isMeasure: true)), treble),
        1.0,
      );
    });

    test('goes where it is put when the document says where', () {
      // Which is how a rest in one voice of two is moved out of the other
      // voice's way.
      expect(
        noteY(
          const Note(
            duration: 1,
            rest: Rest(displayStep: 'F', displayOctave: 5),
            type: 'quarter',
          ),
          treble,
        ),
        0.0,
      );
    });
  });
}
