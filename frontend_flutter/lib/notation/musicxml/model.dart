import '../view/pitch.dart';

/// What a MusicXML document says, as the renderer needs it.
///
/// This is not everything MusicXML can express — it is what can be drawn. A
/// document carries plenty that says how somebody else's engraver laid the
/// score out, and none of that is read: where a note goes on the page is worked
/// out here from the music, so a score written by any program comes out looking
/// like every other score in the app rather than like the program it came from.
///
/// Everything is read as it stands, and nothing is repaired. A measure that
/// does not add up is drawn as far as it goes, because a player holding a
/// slightly broken part still wants to see it.

/// The whole score: what it is called, who wrote it, and what is played.
class MusicXmlScore {
  MusicXmlScore({
    this.workTitle,
    this.workNumber,
    this.movementTitle,
    this.movementNumber,
    this.composers = const [],
    this.lyricists = const [],
    this.parts = const [],
  });

  final String? workTitle;
  final String? workNumber;
  final String? movementTitle;
  final String? movementNumber;
  final List<String> composers;
  final List<String> lyricists;
  final List<Part> parts;

  /// What to call the score. A document that names only one of the two is
  /// common enough to be worth being ready for.
  String get title {
    final named = (workTitle ?? '').trim().isNotEmpty
        ? workTitle!
        : (movementTitle ?? '').trim();
    return named.trim().isEmpty ? 'Untitled score' : named.trim();
  }

  List<String> get creators => [...composers, ...lyricists];
}

/// One player's music, from the first bar to the last.
class Part {
  Part({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.measures,
  });

  /// What the document calls it. A document that gives a part no usable id
  /// still has a part, so the renderer names it by its place instead; see
  /// `ScoreLayout`.
  final String id;

  final String? name;
  final String? abbreviation;
  final List<Measure> measures;
}

/// One bar of one part.
class Measure {
  Measure({
    required this.number,
    required this.items,
    this.implicit = false,
  });

  /// What the document numbers it. It is text rather than a number because a
  /// pickup bar is numbered "0" and a split bar "7a".
  final String number;

  /// Whether it is a bar that is not counted — a pickup, or the second half of
  /// a bar split across a system break.
  final bool implicit;

  /// Everything in the bar, in the order the document puts it. The order is the
  /// music: a backup and then more notes is a second voice, and reordering this
  /// would lose which notes are played together.
  final List<MeasureItem> items;

  Iterable<Note> get notes => items.whereType<Note>();
}

/// Anything that can appear inside a bar.
sealed class MeasureItem {
  const MeasureItem();
}

// ---------------------------------------------------------------------------
// WHAT A BAR IS WRITTEN IN
// ---------------------------------------------------------------------------

/// A change to how the music is written down: how finely time is counted, what
/// key and time it is in, and which clefs the staves carry.
///
/// All of it is optional and all of it persists: what a bar does not restate is
/// what the bar before it said.
class Attributes extends MeasureItem {
  const Attributes({
    this.divisions,
    this.keys = const [],
    this.times = const [],
    this.staves,
    this.clefs = const [],
    this.transpose,
  });

  /// How many of the document's own time units make a quarter note. Every
  /// duration in the part is counted in these.
  final int? divisions;

  final List<KeySignature> keys;
  final List<TimeSignature> times;

  /// How many staves this part is written on. A piano part says two.
  final int? staves;

  final List<Clef> clefs;

  /// What the instrument sounds like against what it reads. It is a property of
  /// the instrument rather than of the music, so transposing a score leaves it
  /// alone — but a score is still drawn with it, since a B flat clarinet part
  /// is written where the clarinettist reads it.
  final Transpose? transpose;
}

/// A key signature, as a count of sharps (positive) or flats (negative).
class KeySignature {
  const KeySignature({required this.fifths, this.staff, this.mode});

  final int fifths;

  /// Which staff of the part it is on, or null for all of them.
  final int? staff;

  final String? mode;
}

class TimeSignature {
  const TimeSignature({
    required this.beats,
    required this.beatType,
    this.staff,
    this.symbol,
  });

  final int beats;
  final int beatType;
  final int? staff;

  /// `common` or `cut` when the document asks for one of the two signs rather
  /// than for the numbers.
  final String? symbol;

  /// How long a whole bar of it is, in quarter notes.
  double get quartersPerMeasure => beats * 4 / beatType;
}

class Clef {
  const Clef({
    required this.sign,
    this.line,
    this.octaveChange = 0,
    this.staff = 1,
  });

  /// `G`, `F`, `C`, `percussion`, `TAB` or `none`.
  final String sign;

  /// Which line of the staff it names, counting from the bottom.
  final int? line;

  /// Whole octaves the part sounds away from where it is written, as an
  /// 8va or 8vb under the clef.
  final int octaveChange;

  final int staff;

  /// The line it sits on when the document does not say, which is what makes a
  /// clef a clef: a G on the second line is a treble clef.
  int get effectiveLine {
    if (line != null) return line!;
    switch (sign.toUpperCase()) {
      case 'G':
        return 2;
      case 'F':
        return 4;
      case 'C':
        return 3;
      default:
        return 3;
    }
  }
}

class Transpose {
  const Transpose({this.diatonic = 0, this.chromatic = 0, this.octaveChange = 0});

  final int diatonic;
  final int chromatic;
  final int octaveChange;
}

// ---------------------------------------------------------------------------
// THE NOTES
// ---------------------------------------------------------------------------

/// One note, one rest, or one note of a chord.
class Note extends MeasureItem {
  const Note({
    required this.duration,
    this.pitch,
    this.rest,
    this.unpitched,
    this.isChord = false,
    this.isGrace = false,
    this.isCue = false,
    this.voice = 1,
    this.staff = 1,
    this.type,
    this.dots = 0,
    this.accidental,
    this.stem,
    this.noteheadType,
    this.beams = const {},
    this.timeModification,
    this.notations = const Notations(),
    this.lyrics = const [],
  });

  /// How long it lasts, in the divisions the part is counted in. A grace note
  /// has none, which is what makes it a grace note.
  final int duration;

  /// What it sounds like. Absent for a rest, and for anything on a drum staff
  /// that is written at a place rather than at a sound.
  final Pitch? pitch;

  /// Where a rest sits, when it is a rest. Both of its fields are optional: a
  /// rest that says nothing is drawn in the middle of the staff.
  final Rest? rest;

  /// Where a drum note sits: a place on the staff rather than a sound.
  final Unpitched? unpitched;

  /// Whether it sounds with the note before it rather than after it.
  final bool isChord;

  final bool isGrace;
  final bool isCue;

  final int voice;
  final int staff;

  /// `whole`, `half`, `quarter`, `eighth`, `16th` and so on. What is drawn
  /// comes from this rather than from the duration: a document is free to write
  /// a quarter note lasting an odd number of divisions, and it is still drawn
  /// as a quarter note.
  final String? type;

  final int dots;

  /// What is printed in front of it. This is not the same as what it sounds
  /// like: a score that leaves it out is a score saying the key signature has
  /// that one covered.
  final String? accidental;

  /// `up`, `down`, `none` or `double`. Absent leaves it to the layout.
  final String? stem;

  final String? noteheadType;

  /// Which beams start, carry on or end here, by beam number. Beam 1 is the
  /// one an eighth note has, beam 2 the second one a sixteenth has.
  final Map<int, String> beams;

  /// What makes a triplet a triplet: three notes in the time of two.
  final TimeModification? timeModification;

  final Notations notations;
  final List<Lyric> lyrics;

  bool get isRest => rest != null;

  /// Whether it is a rest that lasts the whole bar however long the bar is,
  /// which is drawn hanging from the fourth line rather than as a rest of some
  /// particular length.
  bool get isMeasureRest => rest?.isMeasure ?? false;
}

class Rest {
  const Rest({this.displayStep, this.displayOctave, this.isMeasure = false});

  /// Where on the staff to draw it, when the document says. A rest in one voice
  /// of two is moved out of the other voice's way this way.
  final String? displayStep;
  final int? displayOctave;

  final bool isMeasure;
}

class Unpitched {
  const Unpitched({this.displayStep, this.displayOctave});

  final String? displayStep;
  final int? displayOctave;
}

class TimeModification {
  const TimeModification({required this.actualNotes, required this.normalNotes});

  final int actualNotes;
  final int normalNotes;

  double get factor => normalNotes / actualNotes;
}

/// What is written on or around a note: how it is joined to its neighbours, how
/// it is played, and what is held over it.
class Notations {
  const Notations({
    this.tieStarts = false,
    this.tieStops = false,
    this.slurs = const [],
    this.articulations = const [],
    this.ornaments = const [],
    this.fermata = false,
    this.arpeggiate = false,
    this.tuplet,
  });

  final bool tieStarts;
  final bool tieStops;
  final List<Slur> slurs;

  /// SMuFL-ish names: `staccato`, `accent`, `tenuto`, `marcato`,
  /// `staccatissimo`.
  final List<String> articulations;

  /// `trill-mark`, `mordent`, `turn`.
  final List<String> ornaments;

  final bool fermata;
  final bool arpeggiate;

  /// `start` or `stop`, for the bracket and number over a triplet.
  final String? tuplet;
}

class Slur {
  const Slur({required this.number, required this.type, this.placement});

  final int number;

  /// `start`, `stop` or `continue`.
  final String type;

  /// `above` or `below`, when the document says.
  final String? placement;
}

class Lyric {
  const Lyric({required this.text, this.number = 1, this.syllabic, this.extend = false});

  final String text;

  /// Which line of words it belongs to. A song with a first and a second verse
  /// has two.
  final int number;

  /// `single`, `begin`, `middle` or `end` — which decides whether a hyphen is
  /// drawn after it.
  final String? syllabic;

  final bool extend;
}

// ---------------------------------------------------------------------------
// MOVING THE CLOCK
// ---------------------------------------------------------------------------

/// Winds the clock back, which is how a second voice on the same staff is
/// written: the first voice is written to the end of the bar, and then time is
/// wound back to write the second over it.
class Backup extends MeasureItem {
  const Backup(this.duration);

  final int duration;
}

/// Winds the clock forward without writing anything, which is a rest nobody
/// wants drawn.
class Forward extends MeasureItem {
  const Forward(this.duration);

  final int duration;
}

// ---------------------------------------------------------------------------
// WHAT IS WRITTEN AROUND THE NOTES
// ---------------------------------------------------------------------------

/// Something written above or below the staff that is not attached to one
/// note: a word, a dynamic, a hairpin, a tempo.
class Direction extends MeasureItem {
  const Direction({
    this.words,
    this.dynamics,
    this.wedge,
    this.metronome,
    this.placement,
    this.staff = 1,
    this.offset = 0,
  });

  final String? words;

  /// `p`, `mf`, `ff` and the rest, as the letters to set.
  final String? dynamics;

  /// `crescendo`, `diminuendo` or `stop`.
  final String? wedge;

  final String? metronome;

  /// `above` or `below`.
  final String? placement;

  final int staff;

  /// How far from where it is written it actually belongs, in divisions.
  final int offset;
}

/// A chord symbol over the staff.
class Harmony extends MeasureItem {
  const Harmony({
    required this.rootStep,
    this.rootAlter = 0,
    this.kind,
    this.kindText,
    this.bassStep,
    this.bassAlter = 0,
    this.offset = 0,
  });

  final String rootStep;
  final double rootAlter;

  /// `major`, `minor`, `dominant`, `major-seventh` and the rest of the
  /// vocabulary MusicXML names chords with.
  final String? kind;

  /// What the document would rather it were printed as, when it says.
  final String? kindText;

  final String? bassStep;
  final double bassAlter;

  final int offset;
}

/// The line at one end of a bar, and whatever is written on it: a repeat, a
/// first-time bar, the double line at the end.
class Barline extends MeasureItem {
  const Barline({
    this.location = 'right',
    this.barStyle,
    this.repeatDirection,
    this.endingNumber,
    this.endingType,
    this.fermata = false,
  });

  /// `left`, `right` or `middle`.
  final String location;

  /// `light-light`, `light-heavy`, `heavy-light`, `dashed` and so on.
  final String? barStyle;

  /// `forward` or `backward`, for a repeat.
  final String? repeatDirection;

  /// Which time round it is played, as the document writes it: "1", "1,2".
  final String? endingNumber;

  /// `start`, `stop` or `discontinue`.
  final String? endingType;

  final bool fermata;
}

/// What the document asks for about the page: chiefly where it wants a new
/// system or a new page. Only the breaks are read — everything else about how
/// somebody else laid it out is worked out again here.
class Print extends MeasureItem {
  const Print({this.newSystem = false, this.newPage = false});

  final bool newSystem;
  final bool newPage;
}
