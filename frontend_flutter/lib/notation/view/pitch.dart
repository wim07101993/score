/// Reading a note at a distance from where it was written.
///
/// This is the part of transposing that decides whether what comes out is
/// something a player can read. Everything here is arithmetic on letters and
/// semitones and touches no document, which is what makes it the one piece of
/// the engine that can be tested on its own.
library;

/// The letters of the scale, in the order MusicXML counts them.
const List<String> steps = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

/// How far each of those letters stands from C, in semitones.
const List<int> stepSemitones = [0, 2, 4, 5, 7, 9, 11];

/// The same letters in the order the circle of fifths puts them, which is the
/// order a key signature adds accidentals in.
const List<String> fifthsSteps = ['F', 'C', 'G', 'D', 'A', 'E', 'B'];

/// How many letters a transposition moves by, for every distance up to an
/// octave. This is what keeps a transposed score readable: three semitones up
/// is a minor third, which moves two letters, so C becomes E flat and never D
/// sharp — a third is written as a third.
const List<int> stepsPerSemitone = [0, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 6, 7];

/// The furthest round the circle of fifths a key signature can be written.
/// Seven sharps or seven flats is every letter of the scale altered once; past
/// that there is nothing left to alter.
const int mostAccidentals = 7;

/// A note as MusicXML spells one: a letter, how far it is bent, and how high.
class Pitch {
  const Pitch(this.step, this.alter, this.octave);

  /// One of A to G.
  final String step;

  /// Semitones, so 1 is a sharp and -1 a flat. Fractions are quarter-tones,
  /// which this moves without understanding.
  final double alter;

  final int octave;

  @override
  bool operator ==(Object other) =>
      other is Pitch &&
      other.step == step &&
      other.alter == alter &&
      other.octave == octave;

  @override
  int get hashCode => Object.hash(step, alter, octave);

  @override
  String toString() => 'Pitch($step$alter/$octave)';
}

/// How far a transposition moves, said the way a musician says it: so many
/// letters, and so many semitones. A minor third and a major third are both
/// three letters and differ only in the second number, which is exactly the
/// difference between an E flat and an E.
class Interval {
  const Interval(this.steps, this.semitones);

  /// Letters, negative for down.
  final int steps;

  /// Semitones, negative for down.
  final int semitones;

  bool get isNone => steps == 0 && semitones == 0;

  @override
  bool operator ==(Object other) =>
      other is Interval && other.steps == steps && other.semitones == semitones;

  @override
  int get hashCode => Object.hash(steps, semitones);

  @override
  String toString() => 'Interval($steps letters, $semitones semitones)';
}

/// The interval a score is transposed by, which is a question the number of
/// semitones on its own cannot answer.
///
/// Six semitones up from C is an F sharp or a G flat, and nothing in the note
/// itself decides which. Nearly always the plain reading of the distance is the
/// right one and the key follows it: up a semitone is a minor second, so a
/// piece in C goes to D flat.
///
/// What that reading cannot do is stop at a key that can be written down. A
/// piece already a long way round the circle can be transposed clean off the
/// end of it — down a tritone from B flat is a diminished fifth to F flat
/// major, eight flats, a key signature that does not exist. The same sound
/// spelled a letter along is E major with four sharps, which is what a player
/// would be handed. So the plain reading is taken unless it lands somewhere
/// unwritable, and the way out is to move the letter rather than the sound.
///
/// The decision is made once for the whole score, off the key it opens in: a
/// transposition is one interval, and every note and every key change in the
/// piece is moved by that same one.
///
/// [fifths] is the key the score opens in, as a count of sharps (positive) or
/// flats (negative).
Interval intervalFor(int semitones, int fifths) {
  if (semitones == 0) {
    return const Interval(0, 0);
  }

  final octaves = semitones ~/ 12;
  // The sign of the dividend is kept, which Dart's own `%` would not do: a
  // transposition down has to stay a transposition down.
  final rest = semitones.remainder(12);
  final plain = 7 * octaves + rest.sign * stepsPerSemitone[rest.abs()];

  var best = Interval(plain, semitones);
  var accidentals = transposeFifths(fifths, best).abs();
  if (accidentals <= mostAccidentals) {
    return best;
  }

  for (final steps in [plain - 1, plain + 1]) {
    final candidate = Interval(steps, semitones);
    final written = transposeFifths(fifths, candidate).abs();
    if (written < accidentals) {
      best = candidate;
      accidentals = written;
    }
  }
  return best;
}

/// The same note, read at an interval from where it was written.
///
/// The letter moves first and the accidental is worked out afterwards, rather
/// than reaching for whichever letter sits nearest the new sound. That is the
/// whole difference between a score a player can read and one they cannot:
/// transposing a D sharp up a minor third has to give an F sharp and not a G,
/// because the third it is part of is still a third.
///
/// `null` when this is not a note this understands, which is a caller's cue to
/// leave what it has exactly as it found it. Writing a misreading back into a
/// document is worse than leaving a note untransposed: an octave that was never
/// a number would be saved as the word NaN, and a score that was merely strange
/// would come out broken.
Pitch? transposePitch(Pitch pitch, Interval interval) {
  final step = steps.indexOf(pitch.step);
  if (step < 0 || !pitch.alter.isFinite) {
    return null;
  }

  // Where the letter lands, counted in letters from C0 so that running off the
  // end of an octave carries into the next one on its own.
  final letters = step + 7 * pitch.octave + interval.steps;
  // Dart's `%` is never negative for a positive divisor, which is exactly what
  // is wanted here: a letter below C0 still names one of the seven letters.
  final movedStep = letters % 7;
  final movedOctave = (letters / 7).floor();

  // What it has to sound like, less what that letter sounds like on its own.
  // Whatever is left over is the accidental that goes in front of it.
  final sound =
      stepSemitones[step] + pitch.alter + 12 * pitch.octave + interval.semitones;
  final movedAlter = sound - stepSemitones[movedStep] - 12 * movedOctave;

  return Pitch(steps[movedStep], movedAlter, movedOctave);
}

/// The key signature a transposed score is written in, as a count of sharps
/// (positive) or flats (negative).
///
/// This is the tonic moved by the same interval every note moves by, which is
/// what keeps the two of them agreeing: a score whose notes are spelled with
/// flats cannot be handed a key signature full of sharps.
num transposeFifths(int fifths, Interval interval) {
  final tonic = _tonicOf(fifths);
  final moved = transposePitch(Pitch(tonic.step, tonic.alter, 4), interval);
  if (moved == null) {
    return fifths;
  }
  final written = fifthsSteps.indexOf(moved.step) - 1 + 7 * moved.alter;
  return written == written.roundToDouble() ? written.round() : written;
}

/// The key whose signature has this many sharps or flats, as a note.
Pitch _tonicOf(int fifths) {
  final place = fifths + 1;
  return Pitch(
    fifthsSteps[place % 7],
    (place / 7).floor().toDouble(),
    4,
  );
}

/// What to print in front of a note, for the accidentals a score can name.
///
/// `null` for anything stranger than a double sharp, or for a fraction of a
/// semitone, which is left to whoever reads the document to work out from the
/// key.
String? accidentalNameFor(double alter) {
  if (alter != alter.roundToDouble()) {
    return null;
  }
  switch (alter.round()) {
    case -2:
      return 'flat-flat';
    case -1:
      return 'flat';
    case 0:
      return 'natural';
    case 1:
      return 'sharp';
    case 2:
      return 'double-sharp';
  }
  return null;
}

/// A number the way a document writes one: a whole number without a decimal
/// point, so that a score that was never transposed and one that was round-trip
/// to the same text.
String formatNumber(num value) {
  if (value is int) {
    return '$value';
  }
  final asDouble = value.toDouble();
  if (asDouble == asDouble.roundToDouble() && asDouble.isFinite) {
    return '${asDouble.round()}';
  }
  return '$asDouble';
}
