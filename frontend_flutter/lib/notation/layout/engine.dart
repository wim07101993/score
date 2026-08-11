import 'dart:math' as math;
import 'dart:ui' show Offset, TextAlign;

import '../musicxml/model.dart';
import '../render/primitives.dart';
import '../render/smufl.dart';
import 'note_values.dart';
import 'staff_position.dart';

/// Turning a score into something to draw.
///
/// Everything here works in staff spaces — the gap between two lines of a staff
/// — with x running right and y running down. What a staff space is worth in
/// pixels is decided when it is painted, which is what makes zooming free and
/// what lets the whole engine be tested without a screen.
///
/// Where a note goes is worked out from the music rather than read out of the
/// document. MusicXML carries plenty about how somebody else's engraver laid a
/// score out, and none of it is read: a score written by any program comes out
/// looking like every other score in the app rather than like the program it
/// came from.

class LayoutOptions {
  const LayoutOptions({
    this.width = 80,
    this.justify = true,
    this.showPartNames = true,
    this.showTitle = true,
  });

  /// How much room there is across, in staff spaces. Systems are broken to fit
  /// it.
  final double width;

  /// Whether a system is stretched to reach the right margin. The last one is
  /// left as it falls, the way an engraver leaves it.
  final bool justify;

  final bool showPartNames;
  final bool showTitle;
}

// ---------------------------------------------------------------------------
// HOW MUCH ROOM THINGS TAKE
// ---------------------------------------------------------------------------

/// How far apart notes stand.
///
/// A note twice as long does not take twice the room — an engraved score would
/// be unreadably sparse in slow music and cramped in fast — so the width grows
/// more slowly than the duration does. Everything else here is a minimum: how
/// close two noteheads may come, how much room an accidental needs in front of
/// one.
class _Spacing {
  static const double quarterNote = 3.2;
  static const double exponent = 0.55;

  static const double afterNotehead = 0.4;
  static const double beforeAccidental = 0.22;
  static const double afterAccidental = 0.16;
  static const double dot = 0.5;

  static const double measurePadding = 1.1;
  static const double furniturePadding = 0.7;

  static const double staffHeight = 4.0;

  /// Between the bottom line of one staff and the top line of the next.
  static const double staffGapWithinPart = 7.0;
  static const double staffGapBetweenParts = 10.0;

  static const double systemGap = 8.0;
  static const double lyricLine = 2.1;
  /// Room over the top staff of a system, which is where a tempo, a chord
  /// symbol or a rehearsal mark goes. Enough for two of them stacked.
  static const double aboveStaff = 5.0;

  static const double stemLength = 3.5;
  static const double minStemLength = 2.4;

  static double forDuration(double quarters) {
    if (quarters <= 0) {
      return 0;
    }
    return quarterNote * math.pow(quarters, exponent).toDouble();
  }

  /// Roughly how wide a piece of text is. The layout runs without a screen, so
  /// nothing here can measure a font; a lyric only has to widen the note it
  /// sits under by about the right amount, and being a little out moves a
  /// syllable rather than breaking the bar.
  static double text(String text, double size) => text.length * size * 0.56;
}

// ---------------------------------------------------------------------------
// THE MUSIC, READY TO PLACE
// ---------------------------------------------------------------------------

/// One thing that happens at one moment: a note, a chord, or a rest.
class _Group {
  _Group({
    required this.onset,
    required this.staff,
    required this.voice,
    required this.notes,
    required this.value,
    required this.quarters,
    required this.isGrace,
  });

  /// When it happens, in quarter notes from the start of the bar. Quarters
  /// rather than the document's own divisions, because two parts of one score
  /// are free to count in different ones and they still have to line up.
  final double onset;

  final int staff;
  final int voice;

  /// The notes sounding together. More than one is a chord; exactly one that is
  /// a rest is a rest.
  final List<Note> notes;

  final NoteValue value;

  /// What it is worth, dots and tuplets included.
  final double quarters;

  final bool isGrace;

  bool get isRest => notes.length == 1 && notes.first.isRest;

  // Filled in as it is placed.
  double x = 0;
  bool stemUp = true;
  final Map<Note, double> y = {};
  final Map<Note, double> headX = {};
  double stemEndY = 0;
  double stemX = 0;
}

/// One bar of one part, with everything it is written in resolved: what a bar
/// does not restate is what the bar before it said, and that is worked out here
/// so that nothing further on has to remember.
class _Bar {
  _Bar({
    required this.divisions,
    required this.clefs,
    required this.key,
    required this.time,
    required this.staves,
    required this.groups,
    required this.directions,
    required this.harmonies,
    required this.clefsChanged,
    required this.keyChanged,
    required this.timeChanged,
    required this.startsSystem,
    required this.rightBarline,
    required this.leftBarline,
  });

  final int divisions;
  final Map<int, Clef> clefs;
  final KeySignature key;
  final TimeSignature time;
  final int staves;
  final List<_Group> groups;
  final List<(double, Direction)> directions;
  final List<(double, Harmony)> harmonies;

  /// Which staves of this part are given a new clef here. A piano part whose
  /// left hand moves to a bass clef says nothing about its right hand, and
  /// redrawing the right hand's clef would tell the player it had changed.
  final Set<int> clefsChanged;

  final bool keyChanged;
  final bool timeChanged;
  final bool startsSystem;

  final Barline? rightBarline;
  final Barline? leftBarline;
}

/// One staff on the page: which part it belongs to and which of that part's
/// staves it is.
class _StaffRef {
  _StaffRef(this.partIndex, this.staff, this.lyricLines, this.lyricTop);

  final int partIndex;
  final int staff;

  /// How many lines of words hang under it, which is reserved on every system
  /// so that the staves do not shuffle about from one to the next.
  final int lyricLines;

  /// How far under the top of the staff the words begin.
  ///
  /// Far enough to clear the lowest note the part ever goes to, rather than a
  /// fixed distance under the staff: a vocal line that dips below its staff
  /// would otherwise have its own ledger lines drawn through its words. It is
  /// worked out once for the whole part so that the words sit on one line all
  /// the way down the page.
  final double lyricTop;

  double top = 0;

  /// How much room the staff and everything hanging off it take.
  double get height => lyricLines == 0
      ? _Spacing.staffHeight
      : lyricTop + lyricLines * _Spacing.lyricLine;

  /// Where a given line of words is written.
  double lyricBaseline(int line) =>
      lyricTop + (line - 1) * _Spacing.lyricLine + 1.3;
}

// ---------------------------------------------------------------------------
// READING THE PARTS
// ---------------------------------------------------------------------------

/// Walks one part from the first bar to the last, carrying what it is written
/// in forward.
List<_Bar> _readPart(Part part) {
  var divisions = 1;
  var clefs = <int, Clef>{1: const Clef(sign: 'G', line: 2)};
  var key = const KeySignature(fifths: 0);
  var time = const TimeSignature(beats: 4, beatType: 4);
  var staves = 1;

  final bars = <_Bar>[];

  for (final measure in part.measures) {
    final clefsChanged = <int>{};
    var keyChanged = bars.isEmpty;
    var timeChanged = bars.isEmpty;
    var startsSystem = false;

    final groups = <_Group>[];
    final directions = <(double, Direction)>[];
    final harmonies = <(double, Harmony)>[];
    Barline? rightBarline;
    Barline? leftBarline;

    var cursor = 0; // in divisions
    _Group? lastGroup;

    for (final item in measure.items) {
      switch (item) {
        case Attributes():
          if (item.divisions != null) divisions = item.divisions!;
          if (item.staves != null) staves = item.staves!;
          if (item.keys.isNotEmpty) {
            key = item.keys.first;
            keyChanged = true;
          }
          if (item.times.isNotEmpty) {
            time = item.times.first;
            timeChanged = true;
          }
          if (item.clefs.isNotEmpty) {
            clefs = {...clefs};
            for (final clef in item.clefs) {
              if (clefs[clef.staff]?.sign != clef.sign ||
                  clefs[clef.staff]?.effectiveLine != clef.effectiveLine ||
                  clefs[clef.staff]?.octaveChange != clef.octaveChange) {
                clefsChanged.add(clef.staff);
              }
              clefs[clef.staff] = clef;
            }
          }

        case Note():
          final value = valueOf(item);
          if (item.isChord && lastGroup != null) {
            lastGroup.notes.add(item);
            break;
          }
          final group = _Group(
            onset: cursor / divisions,
            staff: item.staff,
            voice: item.voice,
            notes: [item],
            value: value,
            quarters: _quartersOf(item, value),
            isGrace: item.isGrace,
          );
          groups.add(group);
          lastGroup = group;
          cursor += item.duration;

        case Backup():
          cursor -= item.duration;
          lastGroup = null;

        case Forward():
          cursor += item.duration;
          lastGroup = null;

        case Direction():
          directions.add(((cursor + item.offset) / divisions, item));

        case Harmony():
          harmonies.add(((cursor + item.offset) / divisions, item));

        case Barline():
          if (item.location == 'left') {
            leftBarline = item;
          } else {
            rightBarline = item;
          }

        case Print():
          if (item.newSystem || item.newPage) startsSystem = true;
      }
    }

    bars.add(_Bar(
      divisions: divisions,
      clefs: clefs,
      key: key,
      time: time,
      staves: staves,
      groups: groups,
      directions: directions,
      harmonies: harmonies,
      clefsChanged: clefsChanged,
      keyChanged: keyChanged,
      timeChanged: timeChanged,
      startsSystem: startsSystem && bars.isNotEmpty,
      rightBarline: rightBarline,
      leftBarline: leftBarline,
    ));
  }

  return bars;
}

/// What a note is worth in quarter notes: what its type is worth, half as much
/// again for every dot, and less again when it is part of a tuplet.
double _quartersOf(Note note, NoteValue value) {
  if (note.isGrace) {
    return 0;
  }
  var quarters = value.quarters;
  var added = quarters;
  for (var dot = 0; dot < note.dots; dot++) {
    added /= 2;
    quarters += added;
  }
  final tuplet = note.timeModification;
  if (tuplet != null && tuplet.actualNotes > 0) {
    quarters *= tuplet.factor;
  }
  return quarters;
}

// ---------------------------------------------------------------------------
// THE ENGINE
// ---------------------------------------------------------------------------

ScoreDrawing layoutScore(
  MusicXmlScore score, [
  LayoutOptions options = const LayoutOptions(),
]) {
  if (score.parts.isEmpty) {
    return ScoreDrawing.empty;
  }

  final parts = [for (final part in score.parts) _readPart(part)];
  final measureCount =
      parts.fold<int>(0, (most, bars) => math.max(most, bars.length));
  if (measureCount == 0) {
    return ScoreDrawing.empty;
  }

  final staffRefs = _staffRefs(score, parts);
  final prims = <Prim>[];

  var y = 0.0;
  if (options.showTitle) {
    y += 3.4;
    prims.add(TextPrim(score.title, options.width / 2, y,
        size: 2.6, style: TextStyleKind.bold, align: TextAlign.center));
    y += 2.4;
    if (score.creators.isNotEmpty) {
      prims.add(TextPrim(score.creators.join(', '), options.width, y,
          size: 1.5, style: TextStyleKind.italic, align: TextAlign.right));
      y += 1.2;
    }
    y += 2.6;
  }

  // How wide every bar wants to be, both as the first of a system and as one
  // in the middle of one: a bar that opens a system restates the clef and the
  // key, and is wider for it.
  final measures = [
    for (var index = 0; index < measureCount; index++)
      _measureOf(index, parts, staffRefs),
  ];

  final indent = options.showPartNames && score.parts.length > 1
      ? _partNameWidth(score)
      : 0.0;

  final systems = _breakIntoSystems(measures, options, indent);

  for (var index = 0; index < systems.length; index++) {
    final system = systems[index];
    final isLast = index == systems.length - 1;
    y = _drawSystem(
      prims: prims,
      system: system,
      measures: measures,
      staffRefs: staffRefs,
      parts: parts,
      score: score,
      options: options,
      top: y,
      isFirst: index == 0,
      justify: options.justify && !isLast,
      indent: indent,
    );
    y += _Spacing.systemGap;
  }

  return ScoreDrawing(
    prims: prims,
    width: options.width,
    height: y,
  );
}

/// Every staff there is to draw, in the order they are stacked.
List<_StaffRef> _staffRefs(MusicXmlScore score, List<List<_Bar>> parts) {
  final refs = <_StaffRef>[];

  for (var partIndex = 0; partIndex < parts.length; partIndex++) {
    final bars = parts[partIndex];
    final staves =
        bars.fold<int>(1, (most, bar) => math.max(most, bar.staves));

    for (var staff = 1; staff <= staves; staff++) {
      var lyricLines = 0;
      var lowest = _Spacing.staffHeight;

      for (final bar in bars) {
        final clef = bar.clefs[staff] ?? const Clef(sign: 'G', line: 2);
        for (final group in bar.groups) {
          if (group.staff != staff) continue;
          for (final note in group.notes) {
            for (final lyric in note.lyrics) {
              lyricLines = math.max(lyricLines, lyric.number);
            }
            if (!note.isRest) {
              lowest = math.max(lowest, noteY(note, clef));
            }
          }
        }
      }

      // Clear of the lowest note and its ledger lines, but not so far that one
      // note off the bottom of the staff carries the words away from all the
      // others.
      final lyricTop = math.min(
        _Spacing.staffHeight + 5.0,
        math.max(_Spacing.staffHeight + 1.2, lowest + 1.4),
      );
      refs.add(_StaffRef(partIndex, staff, lyricLines, lyricTop));
    }
  }

  return refs;
}

// ---------------------------------------------------------------------------
// ONE BAR, ACROSS EVERY PART
// ---------------------------------------------------------------------------

/// One bar of the score: the same bar of every part, with one set of columns
/// they all hang off so that what sounds together is drawn one above the other.
class _MeasureLayout {
  _MeasureLayout(this.index);

  final int index;

  /// The moments something happens in this bar, in quarter notes, and how far
  /// along each of them is placed.
  final List<double> onsets = [];
  final Map<double, double> columnX = {};

  double furnitureAtSystemStart = 0;
  double furnitureMidSystem = 0;

  /// The room the notes take, which is what is stretched when a system is
  /// justified. The furniture in front of them is not stretched.
  double flexible = 0;

  double widthAtSystemStart(bool showKey) =>
      (showKey ? furnitureAtSystemStart : furnitureMidSystem) + flexible;

  double get widthMidSystem => furnitureMidSystem + flexible;
}

_MeasureLayout _measureOf(
  int index,
  List<List<_Bar>> parts,
  List<_StaffRef> staffRefs,
) {
  final layout = _MeasureLayout(index);

  // Everything that happens anywhere in this bar, whichever part it is in.
  final onsets = <double>{};
  for (final bars in parts) {
    if (index >= bars.length) continue;
    for (final group in bars[index].groups) {
      if (!group.isGrace) onsets.add(group.onset);
    }
  }
  if (onsets.isEmpty) {
    onsets.add(0);
  }

  final sorted = onsets.toList()..sort();
  layout.onsets.addAll(sorted);

  // How much room the busiest part needs at each of those moments.
  final content = <double, double>{};
  final graceBefore = <double, int>{};
  for (final bars in parts) {
    if (index >= bars.length) continue;
    for (final group in bars[index].groups) {
      if (group.isGrace) {
        graceBefore[group.onset] = (graceBefore[group.onset] ?? 0) + 1;
        continue;
      }
      final width = _groupWidth(group);
      content[group.onset] = math.max(content[group.onset] ?? 0, width);
    }
  }

  // The furniture at the front: the clef, the key and the time.
  var atStart = _Spacing.measurePadding;
  var mid = _Spacing.measurePadding;
  for (final bars in parts) {
    if (index >= bars.length) continue;
    final bar = bars[index];
    atStart = math.max(atStart, _furnitureWidth(bar, systemStart: true));
    mid = math.max(mid, _furnitureWidth(bar, systemStart: false));
  }
  layout.furnitureAtSystemStart = atStart;
  layout.furnitureMidSystem = mid;

  var x = 0.0;
  for (var i = 0; i < sorted.length; i++) {
    final onset = sorted[i];
    x += (graceBefore[onset] ?? 0) * 1.5;
    layout.columnX[onset] = x;

    final next = i + 1 < sorted.length ? sorted[i + 1] : null;
    final gap = next == null ? null : next - onset;
    final needed = (content[onset] ?? 1.2) + _Spacing.afterNotehead;
    x += gap == null
        ? needed
        : math.max(_Spacing.forDuration(gap), needed);
  }

  layout.flexible = x + _Spacing.measurePadding;
  return layout;
}

/// How much room one chord takes across: what stands in front of it, the heads
/// themselves, and the dots after them.
double _groupWidth(_Group group) {
  var accidental = 0.0;
  var head = 1.18;
  var dots = 0.0;
  var lyrics = 0.0;

  for (final note in group.notes) {
    if (note.accidental != null) {
      final glyph = accidentalGlyph(note.accidental!);
      if (glyph != null) {
        accidental = math.max(
          accidental,
          glyph.advance + _Spacing.beforeAccidental + _Spacing.afterAccidental,
        );
      }
    }
    dots = math.max(dots, note.dots * _Spacing.dot);

    if (note.isRest) {
      final glyph = restGlyph(note.type ?? 'quarter');
      if (glyph != null) head = math.max(head, glyph.advance);
    } else {
      head = math.max(head, noteheadGlyph(note, group.value).advance);
    }

    // A word under a note pushes the notes apart, or the syllables run into one
    // another. A syllable is centred on its notehead, so what has to fit
    // between two of them is half of each; taking the whole of this one is the
    // simple way to be sure of it, and an engraver spaces sung music that way
    // regardless.
    for (final lyric in note.lyrics) {
      lyrics = math.max(lyrics, _Spacing.text(lyric.text, 1.5) + 0.4);
    }
  }

  return accidental + math.max(head + dots, lyrics);
}

/// How much room the clef, key and time in front of a bar take.
double _furnitureWidth(_Bar bar, {required bool systemStart}) {
  var width = _Spacing.measurePadding;

  if (systemStart || bar.clefsChanged.isNotEmpty) {
    width += 2.9 + _Spacing.furniturePadding;
  }
  if ((systemStart && bar.key.fifths != 0) || bar.keyChanged) {
    width += bar.key.fifths.abs() * 0.9 + _Spacing.furniturePadding;
  }
  if (bar.timeChanged) {
    width += 2.0 + _Spacing.furniturePadding;
  }

  return width;
}

// ---------------------------------------------------------------------------
// BREAKING INTO SYSTEMS
// ---------------------------------------------------------------------------

class _System {
  _System(this.first);

  final int first;
  int last = -1;
  double indent = 0;
}

List<_System> _breakIntoSystems(
    List<_MeasureLayout> measures, LayoutOptions options, double indent) {
  final systems = <_System>[];

  var current = _System(0);

  // The first system is indented by the part names, which is width the bars on
  // it do not get to use.
  var available = options.width - indent;
  var used = 0.0;

  for (var index = 0; index < measures.length; index++) {
    final measure = measures[index];
    final isFirstOfSystem = index == current.first;
    final width = isFirstOfSystem
        ? measure.widthAtSystemStart(true)
        : measure.widthMidSystem;

    if (!isFirstOfSystem && used + width > available) {
      current.last = index - 1;
      systems.add(current);
      current = _System(index);
      available = options.width;
      used = measures[index].widthAtSystemStart(true);
      continue;
    }

    used += width;
  }

  current.last = measures.length - 1;
  systems.add(current);
  return systems;
}

// ---------------------------------------------------------------------------
// DRAWING ONE SYSTEM
// ---------------------------------------------------------------------------

double _drawSystem({
  required List<Prim> prims,
  required _System system,
  required List<_MeasureLayout> measures,
  required List<_StaffRef> staffRefs,
  required List<List<_Bar>> parts,
  required MusicXmlScore score,
  required LayoutOptions options,
  required double top,
  required bool isFirst,
  required bool justify,
  required double indent,
}) {
  // Where each staff of this system sits.
  var y = top + _Spacing.aboveStaff;
  for (var i = 0; i < staffRefs.length; i++) {
    final ref = staffRefs[i];
    ref.top = y;
    y += ref.height;

    if (i + 1 < staffRefs.length) {
      y += staffRefs[i + 1].partIndex == ref.partIndex
          ? _Spacing.staffGapWithinPart
          : _Spacing.staffGapBetweenParts;
    }
  }
  final bottom = y;

  final left = isFirst ? indent : 0.0;

  // What room there is for the notes, once the furniture in front of them is
  // paid for.
  var fixed = left;
  var flexible = 0.0;
  for (var index = system.first; index <= system.last; index++) {
    fixed += index == system.first
        ? measures[index].furnitureAtSystemStart
        : measures[index].furnitureMidSystem;
    flexible += measures[index].flexible;
  }

  // How much the bars have to give to reach the right margin — or to stop
  // short of it. A system whose music will not fit however it is broken is
  // squeezed rather than allowed to run off the page, which is what an
  // engraver does with a bar too full to sit anywhere.
  final room = flexible <= 0 ? 1.0 : (options.width - fixed) / flexible;
  final stretch = justify
      ? math.max(0.35, room)
      : math.min(1.0, math.max(0.35, room));

  // The staves themselves, drawn the whole way across.
  final systemRight = justify
      ? options.width
      : math.min(options.width, fixed + flexible * stretch);

  for (final ref in staffRefs) {
    for (var line = 0; line < 5; line++) {
      prims.add(LinePrim(left, ref.top + line, systemRight, ref.top + line,
          EngravingDefaults.staffLineThickness));
    }
  }

  _drawPartFurniture(
    prims: prims,
    staffRefs: staffRefs,
    score: score,
    left: left,
    isFirst: isFirst,
    showNames: isFirst && options.showPartNames && score.parts.length > 1,
  );

  // The bars.
  var x = left;
  for (var index = system.first; index <= system.last; index++) {
    final measure = measures[index];
    final furniture = index == system.first
        ? measure.furnitureAtSystemStart
        : measure.furnitureMidSystem;
    final width = furniture + measure.flexible * stretch;

    _drawMeasure(
      prims: prims,
      measure: measure,
      parts: parts,
      staffRefs: staffRefs,
      index: index,
      x: x,
      furniture: furniture,
      stretch: stretch,
      atSystemStart: index == system.first,
    );

    x += width;
  }

  // The line at the end of the system, and the one that joins the staves at the
  // start of it.
  _drawBarline(prims, staffRefs, systemRight, parts, system.last, isEnd: true);
  if (staffRefs.length > 1) {
    prims.add(LinePrim(left, staffRefs.first.top, left, _bottomOf(staffRefs.last),
        EngravingDefaults.thinBarlineThickness));
  }

  return bottom;
}

double _bottomOf(_StaffRef ref) => ref.top + _Spacing.staffHeight;

double _partNameWidth(MusicXmlScore score) {
  var width = 0.0;
  for (final part in score.parts) {
    final name = part.name ?? '';
    width = math.max(width, _Spacing.text(name, 1.5));
  }
  return width == 0 ? 0 : width + 1.4;
}

/// What says which staves belong together: the name of the part, and the brace
/// or bracket down the left of its staves.
void _drawPartFurniture({
  required List<Prim> prims,
  required List<_StaffRef> staffRefs,
  required MusicXmlScore score,
  required double left,
  required bool isFirst,
  required bool showNames,
}) {
  var index = 0;
  while (index < staffRefs.length) {
    final partIndex = staffRefs[index].partIndex;
    var last = index;
    while (last + 1 < staffRefs.length &&
        staffRefs[last + 1].partIndex == partIndex) {
      last++;
    }

    final first = staffRefs[index];
    final lastRef = staffRefs[last];

    if (showNames) {
      final name = score.parts[partIndex].name;
      if (name != null && name.trim().isNotEmpty) {
        final middle = (first.top + _bottomOf(lastRef)) / 2;
        prims.add(TextPrim(name, left - 1.0, middle + 0.5,
            size: 1.5, align: TextAlign.right));
      }
    }

    // A part on more than one staff is braced, the way a piano part is.
    if (last > index) {
      prims.add(LinePrim(left - 0.9, first.top, left - 0.9, _bottomOf(lastRef),
          EngravingDefaults.bracketThickness * 0.6));
      prims.add(LinePrim(left - 0.9, first.top, left - 0.4, first.top,
          EngravingDefaults.bracketThickness * 0.6));
      prims.add(LinePrim(left - 0.9, _bottomOf(lastRef), left - 0.4,
          _bottomOf(lastRef), EngravingDefaults.bracketThickness * 0.6));
    }

    index = last + 1;
  }
}

// ---------------------------------------------------------------------------
// DRAWING ONE BAR
// ---------------------------------------------------------------------------

void _drawMeasure({
  required List<Prim> prims,
  required _MeasureLayout measure,
  required List<List<_Bar>> parts,
  required List<_StaffRef> staffRefs,
  required int index,
  required double x,
  required double furniture,
  required double stretch,
  required bool atSystemStart,
}) {
  // What the bar is written in, drawn once per staff.
  for (final ref in staffRefs) {
    final bars = parts[ref.partIndex];
    if (index >= bars.length) continue;
    final bar = bars[index];

    var cursor = x + _Spacing.measurePadding;
    final clef = bar.clefs[ref.staff] ?? const Clef(sign: 'G', line: 2);

    if (atSystemStart || bar.clefsChanged.contains(ref.staff)) {
      cursor = _drawClef(prims, clef, cursor, ref.top);
    }
    if ((atSystemStart && bar.key.fifths != 0) || bar.keyChanged) {
      cursor = _drawKey(prims, bar.key, clef, cursor, ref.top);
    }
    if (bar.timeChanged) {
      cursor = _drawTime(prims, bar.time, cursor, ref.top);
    }
  }

  final notesLeft = x + furniture;

  // The notes.
  for (final ref in staffRefs) {
    final bars = parts[ref.partIndex];
    if (index >= bars.length) continue;
    final bar = bars[index];
    final clef = bar.clefs[ref.staff] ?? const Clef(sign: 'G', line: 2);

    final groups = bar.groups.where((g) => g.staff == ref.staff).toList();
    if (groups.isEmpty) continue;

    // Where each of them goes across.
    for (final group in groups) {
      final column = measure.columnX[group.onset];
      group.x = notesLeft + (column ?? 0) * stretch;
      if (group.isGrace) {
        group.x -= 1.5;
      }
    }

    final voices = groups.map((g) => g.voice).toSet().toList()..sort();
    for (final voice in voices) {
      final ofVoice = groups.where((g) => g.voice == voice).toList();
      _placeVoice(ofVoice, clef, ref.top, voices, voice);
      _drawVoice(prims, ofVoice, ref, clef);
    }

    _drawLyrics(prims, groups, ref);
  }

  // What is written over the top staff: the chord symbols and the words.
  _drawDirections(prims, parts, staffRefs, measure, index, notesLeft, stretch);

  // The line at the end of the bar.
  _drawBarline(prims, staffRefs, x + furniture + measure.flexible * stretch,
      parts, index);
}

/// Which way the stems of a voice go, and how far each note sits from the top
/// of its staff.
void _placeVoice(
  List<_Group> groups,
  Clef clef,
  double staffTop,
  List<int> voices,
  int voice,
) {
  for (final group in groups) {
    for (final note in group.notes) {
      group.y[note] = noteY(note, clef);
    }

    // A staff carrying more than one voice has the first pointing up and the
    // second down, whatever the notes would rather do: that is what tells a
    // reader they are two lines of music and not one chord.
    if (voices.length > 1) {
      group.stemUp = voice == voices.first;
    } else {
      final stated = group.notes.first.stem;
      if (stated == 'up') {
        group.stemUp = true;
      } else if (stated == 'down') {
        group.stemUp = false;
      } else {
        final middle = group.y.values.fold<double>(0, (sum, y) => sum + y) /
            math.max(1, group.y.length);
        group.stemUp = middle >= 2.0;
      }
    }

    group.stemX = 0;
  }
}

void _drawVoice(
  List<Prim> prims,
  List<_Group> groups,
  _StaffRef ref,
  Clef clef,
) {
  // The heads first, which is what everything else is measured from.
  for (final group in groups) {
    _drawHeads(prims, group, ref);
  }

  // Then what joins them: beams where the document asks for them, flags where
  // it does not.
  final beamed = _beamGroups(groups);
  final inABeam = <_Group>{};
  for (final beam in beamed) {
    inABeam.addAll(beam);
  }

  for (final group in groups) {
    if (group.isRest || !group.value.hasStem) continue;
    if (inABeam.contains(group)) continue;
    _drawStemAndFlag(prims, group, ref);
  }

  for (final beam in beamed) {
    _drawBeam(prims, beam, ref);
  }

  _drawTiesAndSlurs(prims, groups, ref);
}

/// The noteheads of one chord, with whatever stands in front of them and the
/// lines they need to sit off the staff.
void _drawHeads(List<Prim> prims, _Group group, _StaffRef ref) {
  final scale = group.isGrace ? 0.62 : 1.0;
  final sorted = [...group.notes]
    ..sort((a, b) => (group.y[a] ?? 0).compareTo(group.y[b] ?? 0));

  // Accidentals stand to the left, each in its own column when two of them
  // would otherwise touch.
  final placed = <(double, double)>[];
  var accidentalRoom = 0.0;
  final accidentals = <(Glyph, double, double)>[];

  for (final note in sorted.reversed) {
    final name = note.accidental;
    if (name == null) continue;
    final glyph = accidentalGlyph(name);
    if (glyph == null) continue;

    final y = group.y[note] ?? 0;
    var column = 0.0;
    while (placed.any((p) =>
        p.$1 == column && (p.$2 - y).abs() < 2.6)) {
      column += glyph.advance + 0.2;
    }
    placed.add((column, y));
    accidentals.add((glyph, column, y));
    accidentalRoom =
        math.max(accidentalRoom, column + glyph.advance + _Spacing.afterAccidental);
  }

  final headLeft = group.x + accidentalRoom;

  for (final entry in accidentals) {
    prims.add(GlyphPrim(
      entry.$1,
      headLeft - _Spacing.afterAccidental - entry.$2 - entry.$1.advance,
      ref.top + entry.$3,
      scale: scale,
      faded: group.isGrace,
    ));
  }

  for (final note in sorted) {
    final y = group.y[note] ?? 0;

    if (note.isRest) {
      final glyph = restGlyph(
          note.isMeasureRest ? 'whole' : (note.type ?? 'quarter'));
      if (glyph != null) {
        prims.add(GlyphPrim(glyph, headLeft, ref.top + y, scale: scale));
      }
      group.headX[note] = headLeft;
      _drawDots(prims, note, headLeft + 1.3, ref.top + y);
      continue;
    }

    final glyph = noteheadGlyph(note, group.value);
    prims.add(GlyphPrim(glyph, headLeft, ref.top + y,
        scale: scale, faded: group.isGrace));
    group.headX[note] = headLeft;

    _drawLedgerLines(prims, y, headLeft, glyph.advance * scale, ref);
    _drawDots(prims, note, headLeft + glyph.advance * scale + 0.25, ref.top + y);
    _drawArticulations(prims, note, headLeft + glyph.advance * scale / 2,
        ref.top + y, group.stemUp);
  }

  group.stemX = group.stemUp
      ? headLeft + (Smufl.noteheadBlack.stemUpSE?[0] ?? 1.18) * scale
      : headLeft + (Smufl.noteheadBlack.stemDownNW?[0] ?? 0.0) * scale;
}

void _drawDots(List<Prim> prims, Note note, double x, double y) {
  if (note.dots == 0) return;

  // A dot goes in a space, so one belonging to a note on a line is nudged up
  // into the space above it.
  final onALine = ((y - 0) * 2).round() % 2 == 0;
  final dotY = onALine ? y - 0.5 : y;

  for (var dot = 0; dot < note.dots; dot++) {
    prims.add(GlyphPrim(Smufl.augmentationDot, x + dot * _Spacing.dot, dotY));
  }
}

void _drawLedgerLines(
    List<Prim> prims, double y, double x, double width, _StaffRef ref) {
  const extension = EngravingDefaults.legerLineExtension;
  final left = x - extension;
  final right = x + width + extension;

  for (var line = -1.0; line >= y - 0.25; line -= 1) {
    prims.add(LinePrim(left, ref.top + line, right, ref.top + line,
        EngravingDefaults.legerLineThickness));
  }
  for (var line = 5.0; line <= y + 0.25; line += 1) {
    prims.add(LinePrim(left, ref.top + line, right, ref.top + line,
        EngravingDefaults.legerLineThickness));
  }
}

void _drawArticulations(
    List<Prim> prims, Note note, double x, double y, bool stemUp) {
  var offset = stemUp ? 1.6 : -1.6;

  for (final articulation in note.notations.articulations) {
    final glyph = switch (articulation) {
      'staccato' => stemUp ? Smufl.articStaccatoBelow : Smufl.articStaccatoAbove,
      'accent' => stemUp ? Smufl.articAccentBelow : Smufl.articAccentAbove,
      'tenuto' => stemUp ? Smufl.articTenutoBelow : Smufl.articTenutoAbove,
      'strong-accent' =>
        stemUp ? Smufl.articMarcatoBelow : Smufl.articMarcatoAbove,
      'staccatissimo' =>
        stemUp ? Smufl.articStaccatissimoBelow : Smufl.articStaccatissimoAbove,
      _ => null,
    };
    if (glyph == null) continue;

    prims.add(GlyphPrim(glyph, x - glyph.advance / 2, y + offset));
    offset += stemUp ? 1.0 : -1.0;
  }

  if (note.notations.fermata) {
    prims.add(GlyphPrim(Smufl.fermataAbove,
        x - Smufl.fermataAbove.advance / 2, y - 2.6));
  }

  for (final ornament in note.notations.ornaments) {
    final glyph = switch (ornament) {
      'trill-mark' => Smufl.ornamentTrill,
      'mordent' => Smufl.ornamentMordent,
      'inverted-mordent' => Smufl.ornamentShortTrill,
      'turn' => Smufl.ornamentTurn,
      _ => null,
    };
    if (glyph == null) continue;
    prims.add(GlyphPrim(glyph, x - glyph.advance / 2, y - 2.4));
  }
}

// ---------------------------------------------------------------------------
// STEMS, FLAGS AND BEAMS
// ---------------------------------------------------------------------------

void _drawStemAndFlag(List<Prim> prims, _Group group, _StaffRef ref) {
  final ys = group.y.values;
  if (ys.isEmpty) return;

  final highest = ys.reduce(math.min);
  final lowest = ys.reduce(math.max);
  final scale = group.isGrace ? 0.62 : 1.0;

  final from = group.stemUp ? lowest : highest;
  var to = group.stemUp
      ? highest - _Spacing.stemLength * scale
      : lowest + _Spacing.stemLength * scale;

  // A stem reaches for the middle line when the note is a long way off the
  // staff, which is what stops a run of high notes growing spidery stems.
  if (group.stemUp && to > 2.0) to = 2.0;
  if (!group.stemUp && to < 2.0) to = 2.0;

  final attach = group.stemUp
      ? (Smufl.noteheadBlack.stemUpSE?[1] ?? 0.168)
      : (Smufl.noteheadBlack.stemDownNW?[1] ?? -0.168);

  prims.add(LinePrim(
    group.stemX,
    ref.top + from - attach * scale,
    group.stemX,
    ref.top + to,
    EngravingDefaults.stemThickness * scale,
  ));
  group.stemEndY = to;

  final flags = group.value.flags;
  if (flags > 0) {
    final glyph = flagGlyph(flags, group.stemUp);
    if (glyph != null) {
      prims.add(GlyphPrim(
        glyph,
        group.stemX - (group.stemUp ? EngravingDefaults.stemThickness / 2 : 0),
        ref.top + to,
        scale: scale,
      ));
    }
  }
}

/// The runs of notes the document asks to be joined by a beam.
List<List<_Group>> _beamGroups(List<_Group> groups) {
  final beams = <List<_Group>>[];
  List<_Group>? current;

  for (final group in groups) {
    if (group.isRest) {
      // A rest inside a beamed run is drawn under the beam and keeps the run
      // going; one outside it ends nothing, because there is nothing to end.
      current?.add(group);
      continue;
    }

    final beam = group.notes.first.beams[1];
    switch (beam) {
      case 'begin':
        current = [group];
        beams.add(current);
      case 'continue':
        current?.add(group);
      case 'end':
        current?.add(group);
        current = null;
      default:
        current = null;
    }
  }

  // A run of one is not a beam: it is a note that says it starts one and never
  // says it ends, which a document can do at a system break.
  return beams
      .map((beam) => beam.where((group) => !group.isRest).toList())
      .where((beam) => beam.length > 1)
      .toList();
}

void _drawBeam(List<Prim> prims, List<_Group> beam, _StaffRef ref) {
  // Which way the whole run points is decided once, by the note that stands
  // furthest from the middle line: a beam has one direction, not one per note.
  var furthest = 0.0;
  var stemUp = true;
  for (final group in beam) {
    for (final y in group.y.values) {
      if ((y - 2.0).abs() >= furthest.abs()) {
        furthest = y - 2.0;
        stemUp = y >= 2.0;
      }
    }
  }
  for (final group in beam) {
    group.stemUp = stemUp;
    // The stem moves to the other side of the head, so where it stands has to
    // be worked out again.
    final head = group.headX.values.isEmpty
        ? group.x
        : group.headX.values.reduce(math.min);
    group.stemX = stemUp
        ? head + (Smufl.noteheadBlack.stemUpSE?[0] ?? 1.18)
        : head + (Smufl.noteheadBlack.stemDownNW?[0] ?? 0.0);
  }

  double reach(_Group group) {
    final ys = group.y.values;
    if (ys.isEmpty) return 2.0;
    return stemUp
        ? ys.reduce(math.min) - _Spacing.stemLength
        : ys.reduce(math.max) + _Spacing.stemLength;
  }

  final first = beam.first;
  final last = beam.last;
  var y0 = reach(first);
  var y1 = reach(last);

  // A beam slopes, but only a little: an engraver would rather it were nearly
  // flat than that it followed every note.
  final run = last.stemX - first.stemX;
  final maxRise = math.min(2.0, run * 0.25);
  final rise = (y1 - y0).clamp(-maxRise, maxRise);
  y1 = y0 + rise;

  double at(double x) =>
      run == 0 ? y0 : y0 + (y1 - y0) * (x - first.stemX) / run;

  // Every stem has to reach the beam, and none of them may end up stubby, so
  // the whole line is pushed away until the shortest of them is long enough.
  var push = 0.0;
  for (final group in beam) {
    final ys = group.y.values;
    if (ys.isEmpty) continue;
    final head = stemUp ? ys.reduce(math.min) : ys.reduce(math.max);
    final length = stemUp ? head - at(group.stemX) : at(group.stemX) - head;
    final short = _Spacing.minStemLength - length;
    if (short > push) push = short;
  }
  if (push > 0) {
    y0 += stemUp ? -push : push;
    y1 += stemUp ? -push : push;
  }

  // The stems.
  for (final group in beam) {
    final ys = group.y.values;
    if (ys.isEmpty) continue;
    final from = stemUp ? ys.reduce(math.max) : ys.reduce(math.min);
    final attach = stemUp
        ? (Smufl.noteheadBlack.stemUpSE?[1] ?? 0.168)
        : (Smufl.noteheadBlack.stemDownNW?[1] ?? -0.168);
    final to = at(group.stemX);

    prims.add(LinePrim(group.stemX, ref.top + from - attach, group.stemX,
        ref.top + to, EngravingDefaults.stemThickness));
    group.stemEndY = to;
  }

  // The beams themselves, one line for an eighth and one more for every
  // halving after that.
  final levels = beam.fold<int>(
      1, (most, group) => math.max(most, group.value.flags));

  for (var level = 1; level <= levels; level++) {
    for (final run in _beamRuns(beam, level)) {
      _drawBeamLine(prims, run, level, stemUp, at, ref, beam);
    }
  }
}

/// Which stretches of a beamed run carry the beam at a given level. The first
/// level runs the whole way; the ones above it come and go with the sixteenths.
List<List<_Group>> _beamRuns(List<_Group> beam, int level) {
  if (level == 1) {
    return [beam];
  }

  final runs = <List<_Group>>[];
  List<_Group>? current;

  for (final group in beam) {
    if (group.value.flags >= level) {
      current ??= [];
      current.add(group);
    } else if (current != null) {
      runs.add(current);
      current = null;
    }
  }
  if (current != null) runs.add(current);

  return runs;
}

void _drawBeamLine(
  List<Prim> prims,
  List<_Group> run,
  int level,
  bool stemUp,
  double Function(double) at,
  _StaffRef ref,
  List<_Group> whole,
) {
  const thickness = EngravingDefaults.beamThickness;
  const spacing = EngravingDefaults.beamSpacing;
  final offset = (level - 1) * (thickness + spacing);

  double x1;
  double x2;
  if (run.length == 1) {
    // A single sixteenth in a run of eighths gets a hook rather than a beam,
    // pointing back towards the note it belongs with.
    final only = run.first;
    final isFirst = identical(only, whole.first);
    x1 = isFirst ? only.stemX : only.stemX - 1.0;
    x2 = isFirst ? only.stemX + 1.0 : only.stemX;
  } else {
    x1 = run.first.stemX;
    x2 = run.last.stemX;
  }

  final half = EngravingDefaults.stemThickness / 2;
  final top1 = at(x1) + (stemUp ? offset : -offset - thickness);
  final top2 = at(x2) + (stemUp ? offset : -offset - thickness);

  prims.add(FillPrim([
    Offset(x1 - half, ref.top + top1),
    Offset(x2 + half, ref.top + top2),
    Offset(x2 + half, ref.top + top2 + thickness),
    Offset(x1 - half, ref.top + top1 + thickness),
  ]));
}

// ---------------------------------------------------------------------------
// TIES AND SLURS
// ---------------------------------------------------------------------------

void _drawTiesAndSlurs(List<Prim> prims, List<_Group> groups, _StaffRef ref) {
  // A tie joins two soundings of the same note; a slur joins whatever it is
  // drawn over. Both are only drawn when both ends are in this bar — one that
  // runs into the next bar is left off rather than drawn to the wrong place.
  for (var i = 0; i < groups.length; i++) {
    final group = groups[i];

    for (final note in group.notes) {
      if (!note.notations.tieStarts || note.pitch == null) continue;

      for (var j = i + 1; j < groups.length; j++) {
        final later = groups[j];
        final match = later.notes.where((candidate) =>
            candidate.pitch == note.pitch && candidate.notations.tieStops);
        if (match.isEmpty) continue;

        final to = match.first;
        final y1 = group.y[note] ?? 0;
        final y2 = later.y[to] ?? 0;
        final up = !group.stemUp;

        prims.add(CurvePrim(
          from: Offset((group.headX[note] ?? group.x) + 1.3,
              ref.top + y1 + (up ? -0.6 : 0.6)),
          to: Offset(later.headX[to] ?? later.x, ref.top + y2 + (up ? -0.6 : 0.6)),
          bow: up ? -0.8 : 0.8,
          thickness: EngravingDefaults.tieMidpointThickness,
        ));
        break;
      }
    }
  }

  // Slurs, matched up by the number the document gives them.
  final open = <int, (_Group, Note)>{};
  for (final group in groups) {
    for (final note in group.notes) {
      for (final slur in note.notations.slurs) {
        if (slur.type == 'start') {
          open[slur.number] = (group, note);
        } else if (slur.type == 'stop') {
          final from = open.remove(slur.number);
          if (from == null) continue;

          final y1 = from.$1.y[from.$2] ?? 0;
          final y2 = group.y[note] ?? 0;
          final up = slur.placement == 'above' ||
              (slur.placement == null && !from.$1.stemUp);

          prims.add(CurvePrim(
            from: Offset((from.$1.headX[from.$2] ?? from.$1.x) + 0.6,
                ref.top + y1 + (up ? -1.5 : 1.5)),
            to: Offset((group.headX[note] ?? group.x) + 0.6,
                ref.top + y2 + (up ? -1.5 : 1.5)),
            bow: up ? -1.2 : 1.2,
            thickness: EngravingDefaults.slurMidpointThickness,
          ));
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// WORDS
// ---------------------------------------------------------------------------

void _drawLyrics(List<Prim> prims, List<_Group> groups, _StaffRef ref) {
  if (ref.lyricLines == 0) return;

  // Gathered a line at a time, because a syllable in the middle of a word is
  // joined to the next one by a hyphen, and where that goes is a question about
  // the syllable after it rather than about this one.
  final byLine = <int, List<(double, Lyric)>>{};

  for (final group in groups) {
    for (final note in group.notes) {
      for (final lyric in note.lyrics) {
        if (lyric.text.trim().isEmpty) continue;
        final line = math.max(1, lyric.number);
        (byLine[line] ??= []).add(((group.headX[note] ?? group.x) + 0.59, lyric));
      }
    }
  }

  for (final entry in byLine.entries) {
    final written = entry.value..sort((a, b) => a.$1.compareTo(b.$1));
    final y = ref.top + ref.lyricBaseline(entry.key);

    for (var i = 0; i < written.length; i++) {
      final (x, lyric) = written[i];
      prims.add(TextPrim(lyric.text, x, y, size: 1.5, align: TextAlign.center));

      // Halfway to the syllable it belongs with. A word split across a barline
      // keeps its hyphen to itself, since the next syllable is in the next bar
      // and this only knows about this one.
      final joins = lyric.syllabic == 'begin' || lyric.syllabic == 'middle';
      if (joins && i + 1 < written.length) {
        prims.add(TextPrim('-', (x + written[i + 1].$1) / 2, y,
            size: 1.5, align: TextAlign.center));
      }
    }
  }
}

void _drawDirections(
  List<Prim> prims,
  List<List<_Bar>> parts,
  List<_StaffRef> staffRefs,
  _MeasureLayout measure,
  int index,
  double notesLeft,
  double stretch,
) {
  for (final ref in staffRefs) {
    final bars = parts[ref.partIndex];
    if (index >= bars.length) continue;
    final bar = bars[index];

    // Only the top staff of a part carries what is written above it.
    final isTopOfPart = staffRefs
        .firstWhere((candidate) => candidate.partIndex == ref.partIndex)
        .staff == ref.staff;
    if (!isTopOfPart) continue;

    double xOf(double onset) {
      final column = measure.columnX[onset] ??
          measure.columnX[measure.onsets.firstWhere((o) => o >= onset,
              orElse: () => measure.onsets.first)] ??
          0;
      return notesLeft + column * stretch;
    }

    // Two things written over the same beat are stacked rather than drawn on
    // top of one another: a tempo and a rehearsal mark at the head of a piece
    // are both written there, and one of them hiding the other is worse than
    // either of them sitting a little high.
    final above = <double, int>{};
    final below = <double, int>{};

    double stack(double onset, bool isBelow) {
      final levels = isBelow ? below : above;
      final level = levels[onset] ?? 0;
      levels[onset] = level + 1;
      return isBelow
          ? ref.top + _Spacing.staffHeight + 1.9 + level * 1.7
          : ref.top - 1.4 - level * 1.7;
    }

    for (final (onset, harmony) in bar.harmonies) {
      prims.add(TextPrim(harmonyText(harmony), xOf(onset), stack(onset, false),
          size: 1.6, style: TextStyleKind.bold));
    }

    for (final (onset, direction) in bar.directions) {
      final isBelow = direction.placement == 'below';

      if (direction.dynamics != null) {
        final y = stack(onset, isBelow);
        var x = xOf(onset);
        for (final letter in direction.dynamics!.split('')) {
          final glyph = switch (letter) {
            'p' => Smufl.dynamicPiano,
            'm' => Smufl.dynamicMezzo,
            'f' => Smufl.dynamicForte,
            'r' => Smufl.dynamicRinforzando,
            's' => Smufl.dynamicSforzando,
            'z' => Smufl.dynamicZ,
            'n' => Smufl.dynamicNiente,
            _ => null,
          };
          if (glyph == null) continue;
          prims.add(GlyphPrim(glyph, x, y));
          x += glyph.advance;
        }
      } else if (direction.words != null) {
        prims.add(TextPrim(direction.words!, xOf(onset), stack(onset, isBelow),
            size: 1.5, style: TextStyleKind.italic));
      } else if (direction.metronome != null) {
        prims.add(TextPrim(direction.metronome!, xOf(onset),
            stack(onset, isBelow), size: 1.4));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// WHAT A BAR IS WRITTEN IN
// ---------------------------------------------------------------------------

double _drawClef(List<Prim> prims, Clef clef, double x, double staffTop) {
  final glyph = _clefGlyph(clef);
  if (glyph == null) {
    return x;
  }

  final y = staffTop + (5 - clef.effectiveLine);
  prims.add(GlyphPrim(glyph, x, y));
  return x + glyph.advance + _Spacing.furniturePadding;
}

Glyph? _clefGlyph(Clef clef) {
  switch (clef.sign.toUpperCase()) {
    case 'G':
      return switch (clef.octaveChange) {
        -1 => Smufl.gClef8vb,
        1 => Smufl.gClef8va,
        -2 => Smufl.gClef15mb,
        2 => Smufl.gClef15ma,
        _ => Smufl.gClef,
      };
    case 'F':
      return switch (clef.octaveChange) {
        -1 => Smufl.fClef8vb,
        1 => Smufl.fClef8va,
        _ => Smufl.fClef,
      };
    case 'C':
      return clef.octaveChange == -1 ? Smufl.cClef8vb : Smufl.cClef;
    case 'PERCUSSION':
      return Smufl.unpitchedPercussionClef1;
    case 'TAB':
      return Smufl.sixStringTabClef;
    case 'NONE':
      return null;
  }
  return Smufl.gClef;
}

double _drawKey(
    List<Prim> prims, KeySignature key, Clef clef, double x, double staffTop) {
  if (key.fifths == 0) {
    return x;
  }

  final sharps = key.fifths > 0;
  final count = math.min(7, key.fifths.abs());
  final glyph = sharps ? Smufl.accidentalSharp : Smufl.accidentalFlat;

  var cursor = x;
  for (var i = 0; i < count; i++) {
    final place = keySignaturePlace(
        sharps ? trebleSharpPlaces[i] : trebleFlatPlaces[i], clef);
    prims.add(GlyphPrim(glyph, cursor, staffTop + place * 0.5));
    cursor += glyph.advance * 0.92;
  }

  return cursor + _Spacing.furniturePadding;
}

double _drawTime(
    List<Prim> prims, TimeSignature time, double x, double staffTop) {
  if (time.symbol == 'common' || time.symbol == 'cut') {
    final glyph =
        time.symbol == 'common' ? Smufl.timeSigCommon : Smufl.timeSigCutCommon;
    prims.add(GlyphPrim(glyph, x, staffTop + 2.0));
    return x + glyph.advance + _Spacing.furniturePadding;
  }

  final beats = _digits(time.beats);
  final beatType = _digits(time.beatType);
  final width = math.max(_digitsWidth(beats), _digitsWidth(beatType));

  _drawDigits(prims, beats, x + (width - _digitsWidth(beats)) / 2, staffTop + 1.0);
  _drawDigits(
      prims, beatType, x + (width - _digitsWidth(beatType)) / 2, staffTop + 3.0);

  return x + width + _Spacing.furniturePadding;
}

List<Glyph> _digits(int number) {
  const glyphs = [
    Smufl.timeSig0,
    Smufl.timeSig1,
    Smufl.timeSig2,
    Smufl.timeSig3,
    Smufl.timeSig4,
    Smufl.timeSig5,
    Smufl.timeSig6,
    Smufl.timeSig7,
    Smufl.timeSig8,
    Smufl.timeSig9,
  ];
  return [
    for (final digit in math.max(0, number).toString().split(''))
      glyphs[int.tryParse(digit) ?? 0],
  ];
}

double _digitsWidth(List<Glyph> digits) =>
    digits.fold<double>(0, (sum, glyph) => sum + glyph.advance);

void _drawDigits(List<Prim> prims, List<Glyph> digits, double x, double y) {
  var cursor = x;
  for (final glyph in digits) {
    prims.add(GlyphPrim(glyph, cursor, y));
    cursor += glyph.advance;
  }
}

// ---------------------------------------------------------------------------
// BARLINES
// ---------------------------------------------------------------------------

void _drawBarline(
  List<Prim> prims,
  List<_StaffRef> staffRefs,
  double x,
  List<List<_Bar>> parts,
  int index, {
  bool isEnd = false,
}) {
  // What kind of line it is, is the same for every staff: it is the end of a
  // bar of the score, not of one part.
  Barline? barline;
  for (final bars in parts) {
    if (index < 0 || index >= bars.length) continue;
    barline ??= bars[index].rightBarline;
  }

  final style = barline?.barStyle;
  final repeat = barline?.repeatDirection;

  for (final ref in staffRefs) {
    final top = ref.top;
    final bottom = ref.top + _Spacing.staffHeight;

    if (repeat == 'backward' || style == 'light-heavy' || (isEnd && style == null && index == parts.first.length - 1)) {
      prims.add(LinePrim(x - 0.5, top, x - 0.5, bottom,
          EngravingDefaults.thinBarlineThickness));
      prims.add(LinePrim(x - 0.15, top, x - 0.15, bottom,
          EngravingDefaults.thickBarlineThickness));
    } else if (style == 'light-light') {
      prims.add(LinePrim(x - 0.45, top, x - 0.45, bottom,
          EngravingDefaults.thinBarlineThickness));
      prims.add(LinePrim(x - 0.05, top, x - 0.05, bottom,
          EngravingDefaults.thinBarlineThickness));
    } else if (style == 'none') {
      // Nothing at all, which is what a bar that runs into the next one asks
      // for.
    } else {
      prims.add(LinePrim(
          x, top, x, bottom, EngravingDefaults.thinBarlineThickness));
    }

    if (repeat == 'backward') {
      prims.add(GlyphPrim(Smufl.repeatDot, x - 1.3, top + 1.5));
      prims.add(GlyphPrim(Smufl.repeatDot, x - 1.3, top + 2.5));
    }
  }
}
