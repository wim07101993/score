import '../musicxml/model.dart';
import '../render/smufl.dart';
import '../view/pitch.dart';

/// How long the note types last and what they are drawn with.
///
/// What is drawn comes from the type the document states rather than from the
/// duration it states: a document is free to write a quarter note lasting an
/// odd number of divisions — a swung eighth, a tuplet, an engraver being
/// approximate — and it is still drawn as a quarter note.

/// One note type: what it is worth, and what it takes to draw it.
class NoteValue {
  const NoteValue(this.type, this.quarters, this.flags, this.notehead,
      {this.hasStem = true});

  final String type;

  /// What it is worth in quarter notes, before dots and tuplets.
  final double quarters;

  /// How many flags it has on its own, which is also how many beams it takes
  /// when it is beamed to its neighbours.
  final int flags;

  /// The SMuFL name of the head it is drawn with.
  final String notehead;

  final bool hasStem;
}

const List<NoteValue> _values = [
  NoteValue('maxima', 32, 0, 'noteheadDoubleWhole', hasStem: false),
  NoteValue('long', 16, 0, 'noteheadDoubleWhole', hasStem: false),
  NoteValue('breve', 8, 0, 'noteheadDoubleWhole', hasStem: false),
  NoteValue('whole', 4, 0, 'noteheadWhole', hasStem: false),
  NoteValue('half', 2, 0, 'noteheadHalf'),
  NoteValue('quarter', 1, 0, 'noteheadBlack'),
  NoteValue('eighth', 0.5, 1, 'noteheadBlack'),
  NoteValue('16th', 0.25, 2, 'noteheadBlack'),
  NoteValue('32nd', 0.125, 3, 'noteheadBlack'),
  NoteValue('64th', 0.0625, 4, 'noteheadBlack'),
  NoteValue('128th', 0.03125, 5, 'noteheadBlack'),
  NoteValue('256th', 0.015625, 6, 'noteheadBlack'),
  NoteValue('512th', 0.0078125, 7, 'noteheadBlack'),
  NoteValue('1024th', 0.00390625, 8, 'noteheadBlack'),
];

final Map<String, NoteValue> _byType = {
  for (final value in _values) value.type: value,
};

/// The type a note is drawn as. A note that does not say is drawn as a quarter,
/// which is the least wrong guess there is: it is the only type that is neither
/// flagged nor hollow, so it is the one whose being wrong shows least.
NoteValue valueOf(Note note) =>
    _byType[note.type ?? ''] ?? _byType['quarter']!;

/// The rest of a given type, as a glyph.
Glyph? restGlyph(String type) {
  switch (type) {
    case 'maxima':
      return Smufl.restMaxima;
    case 'long':
      return Smufl.restLonga;
    case 'breve':
      return Smufl.restDoubleWhole;
    case 'whole':
      return Smufl.restWhole;
    case 'half':
      return Smufl.restHalf;
    case 'quarter':
      return Smufl.restQuarter;
    case 'eighth':
      return Smufl.rest8th;
    case '16th':
      return Smufl.rest16th;
    case '32nd':
      return Smufl.rest32nd;
    case '64th':
      return Smufl.rest64th;
    case '128th':
      return Smufl.rest128th;
  }
  return Smufl.restQuarter;
}

/// The flag a stem carries when the note is not beamed to anything.
Glyph? flagGlyph(int flags, bool up) {
  switch (flags) {
    case 1:
      return up ? Smufl.flag8thUp : Smufl.flag8thDown;
    case 2:
      return up ? Smufl.flag16thUp : Smufl.flag16thDown;
    case 3:
      return up ? Smufl.flag32ndUp : Smufl.flag32ndDown;
    case 4:
      return up ? Smufl.flag64thUp : Smufl.flag64thDown;
    case 5:
      return up ? Smufl.flag128thUp : Smufl.flag128thDown;
  }
  return null;
}

/// The head a note is drawn with, which the document can ask to be something
/// other than the usual one — a cross for a spoken note, a diamond for a
/// harmonic.
Glyph noteheadGlyph(Note note, NoteValue value) {
  final asked = note.noteheadType;
  if (asked != null) {
    final hollow = value.quarters >= 2;
    switch (asked) {
      case 'x':
        return value.quarters >= 4
            ? Smufl.noteheadXWhole
            : hollow
                ? Smufl.noteheadXHalf
                : Smufl.noteheadXBlack;
      case 'diamond':
        return value.quarters >= 4
            ? Smufl.noteheadDiamondWhole
            : hollow
                ? Smufl.noteheadDiamondHalf
                : Smufl.noteheadDiamondBlack;
      case 'slash':
        return Smufl.noteheadSlashHorizontalEnds;
      case 'triangle':
        return Smufl.noteheadTriangleUpBlack;
    }
  }
  return Smufl.byName(value.notehead) ?? Smufl.noteheadBlack;
}

/// What an accidental is drawn with, by the name MusicXML calls it.
Glyph? accidentalGlyph(String name) {
  switch (name) {
    case 'flat-flat':
    case 'double-flat':
      return Smufl.accidentalDoubleFlat;
    case 'flat':
      return Smufl.accidentalFlat;
    case 'natural':
      return Smufl.accidentalNatural;
    case 'sharp':
      return Smufl.accidentalSharp;
    case 'double-sharp':
    case 'sharp-sharp':
      return Smufl.accidentalDoubleSharp;
    case 'quarter-flat':
      return Smufl.accidentalQuarterToneFlatStein;
    case 'quarter-sharp':
      return Smufl.accidentalQuarterToneSharpStein;
  }
  return null;
}

/// What a chord symbol is written as: the letter, how it is bent, and what
/// kind of chord it is.
///
/// MusicXML names a chord by a vocabulary of kinds rather than by the text a
/// reader sees, so the text has to be written back out — unless the document
/// says what it would rather be printed as, which is what a lead sheet written
/// by hand usually does.
String harmonyText(Harmony harmony) {
  final root = harmony.rootStep + _alterSign(harmony.rootAlter);
  final quality = harmony.kindText ?? _kindText(harmony.kind);
  final bass = harmony.bassStep == null
      ? ''
      : '/${harmony.bassStep}${_alterSign(harmony.bassAlter)}';
  return '$root$quality$bass';
}

String _alterSign(double alter) {
  if (alter == 0) return '';
  if (alter == 1) return '♯';
  if (alter == -1) return '♭';
  if (alter == 2) return '♯♯';
  if (alter == -2) return '♭♭';
  return formatNumber(alter);
}

String _kindText(String? kind) {
  switch (kind) {
    case null:
    case 'major':
      return '';
    case 'minor':
      return 'm';
    case 'augmented':
      return '+';
    case 'diminished':
      return '°';
    case 'dominant':
      return '7';
    case 'major-seventh':
      return 'maj7';
    case 'minor-seventh':
      return 'm7';
    case 'diminished-seventh':
      return '°7';
    case 'augmented-seventh':
      return '+7';
    case 'half-diminished':
      return 'm7♭5';
    case 'major-minor':
      return 'mMaj7';
    case 'major-sixth':
      return '6';
    case 'minor-sixth':
      return 'm6';
    case 'dominant-ninth':
      return '9';
    case 'major-ninth':
      return 'maj9';
    case 'minor-ninth':
      return 'm9';
    case 'dominant-11th':
      return '11';
    case 'dominant-13th':
      return '13';
    case 'suspended-second':
      return 'sus2';
    case 'suspended-fourth':
      return 'sus4';
    case 'power':
      return '5';
    case 'none':
      return 'N.C.';
  }
  return kind;
}
