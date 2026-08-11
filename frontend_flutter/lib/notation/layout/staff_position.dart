import 'dart:math' as math;

import '../musicxml/model.dart';

/// Where a note sits on a staff.
///
/// This is the one piece of geometry everything else in the renderer is built
/// on: get it wrong and every note of the score is on the wrong line, however
/// well the rest of it draws. It is its own file, and directly tested, for
/// exactly that reason.
///
/// A staff is measured from the top line down, in staff spaces: the top line is
/// 0, the bottom line is 4, and each step of the scale is half a space. Notes
/// above the staff are negative and notes below it are past 4, which is where
/// the ledger lines go.

const List<String> _stepOrder = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

/// A note counted in letters from C0, which is what makes an octave seven of
/// something and lets a transposition carry from one into the next.
int diatonic(String step, int octave) =>
    octave * 7 + math.max(0, _stepOrder.indexOf(step.toUpperCase()));

/// The note a clef names, with an 8va or 8vb taken into account.
///
/// A part written in a treble clef with an 8 under it is read an octave along,
/// which moves every note on it: a guitar's middle C is written where a
/// pianist's C5 would be.
int clefReference(Clef clef) {
  final base = switch (clef.sign.toUpperCase()) {
    'G' => diatonic('G', 4),
    'F' => diatonic('F', 3),
    'C' => diatonic('C', 4),
    // A staff that is not about pitch at all — a drum staff, a tab staff — is
    // read as though it carried a treble clef, so that whatever is written at
    // a place on it lands at that place.
    _ => diatonic('B', 4),
  };
  return base + 7 * clef.octaveChange;
}

/// Which note sits on the top line of a staff carrying this clef.
int topLineDiatonic(Clef clef) =>
    clefReference(clef) + 2 * (5 - clef.effectiveLine);

/// How far below the top line of the staff a note sits, in staff spaces.
double staffY(Clef clef, String step, int octave) =>
    (topLineDiatonic(clef) - diatonic(step, octave)) * 0.5;

/// Where a note goes, whatever kind of note it is.
double noteY(Note note, Clef clef) {
  final pitch = note.pitch;
  if (pitch != null) {
    return staffY(clef, pitch.step, pitch.octave);
  }

  final unpitched = note.unpitched;
  if (unpitched?.displayStep != null) {
    return staffY(clef, unpitched!.displayStep!, unpitched.displayOctave ?? 4);
  }

  final rest = note.rest;
  if (rest?.displayStep != null) {
    return staffY(clef, rest!.displayStep!, rest.displayOctave ?? 4);
  }

  // A rest that says nothing about where it goes: one that lasts the whole bar
  // hangs from the second line down, and everything else sits in the middle.
  if (note.isMeasureRest || note.type == 'whole') {
    return 1.0;
  }
  return 2.0;
}

/// How far a key signature written for this clef is moved from where it would
/// be written for a treble one.
///
/// The accidentals of a key signature are not written at any particular octave:
/// they are written where they fit on the staff. So the treble placement is
/// moved by the difference between the two clefs, brought back to within half
/// an octave — which is what keeps the signature on the staff rather than
/// several ledger lines above it.
double keySignatureShift(Clef clef) {
  final difference =
      topLineDiatonic(clef) - topLineDiatonic(const Clef(sign: 'G', line: 2));
  return (difference + 7 * (-difference / 7).round()).toDouble();
}

/// Where the accidentals of a key signature go in a treble clef, in half staff
/// spaces below the top line.
///
/// The sharps are added in the order F C G D A E B and the flats in the reverse
/// of it, so the place in these lists is the number of them the signature has.
const List<double> trebleSharpPlaces = [0, 3, -1, 2, 5, 1, 4];
const List<double> trebleFlatPlaces = [4, 1, 5, 2, 6, 3, 7];

/// Where one accidental of a key signature goes on a staff carrying this clef.
///
/// Moving the whole signature by [keySignatureShift] is right nearly always,
/// and in a tenor clef it puts the third sharp a full space above the staff. A
/// key signature is never written off the staff — there is nothing above the
/// top line for it to mean — so an accidental that lands out there is written
/// an octave along instead, which is the same accidental in a place a reader
/// expects to find one.
///
/// A sharp sitting just above the top line is not out there: that is where the
/// third one goes in a treble clef, and every reader knows it.
double keySignaturePlace(double treblePlace, Clef clef) {
  var place = treblePlace + keySignatureShift(clef);
  while (place < -1) {
    place += 7;
  }
  while (place > 9) {
    place -= 7;
  }
  return place;
}
