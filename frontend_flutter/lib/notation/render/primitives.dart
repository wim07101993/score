import 'dart:ui';

import 'smufl.dart';

/// What a laid-out score is made of.
///
/// The engine hands back a flat list of these rather than a tree of musical
/// objects, and the painter does nothing but draw them in order. That split is
/// what makes the layout testable without a screen: where a notehead ends up is
/// a number in a list, which a test can read.
///
/// Every measurement is in staff spaces — the gap between two lines of a staff
/// — with x running right and y running down from the top of the drawing. What
/// one staff space is worth in pixels is the painter's business and nobody
/// else's, which is what makes zooming free.
sealed class Prim {
  const Prim();
}

/// A glyph of the music font.
class GlyphPrim extends Prim {
  const GlyphPrim(this.glyph, this.x, this.y, {this.scale = 1.0, this.faded = false});

  final Glyph glyph;

  /// Where the glyph's own origin goes, which for a notehead is the left of it
  /// at the height of the note, and for a clef is the line it names.
  final double x;
  final double y;

  /// Smaller than life, for a grace note or a cue.
  final double scale;

  /// Drawn in the lighter of the two inks, for something that is there for
  /// reference rather than to be played.
  final bool faded;
}

/// A straight line of a given thickness: a staff line, a stem, a barline, a
/// ledger line.
class LinePrim extends Prim {
  const LinePrim(this.x1, this.y1, this.x2, this.y2, this.thickness);

  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double thickness;
}

/// A filled shape: a beam, the thick half of a repeat barline.
class FillPrim extends Prim {
  const FillPrim(this.points);

  /// The corners, in order. Beams are parallelograms rather than rectangles,
  /// which is why this is not a rect.
  final List<Offset> points;
}

/// A curve drawn thin at the ends and thick in the middle: a tie, a slur.
class CurvePrim extends Prim {
  const CurvePrim({
    required this.from,
    required this.to,
    required this.bow,
    this.thickness = 0.22,
  });

  final Offset from;
  final Offset to;

  /// How far the middle of it stands off the line between its ends. Negative
  /// arches upward, which is where a slur over a run of notes goes.
  final double bow;

  final double thickness;
}

/// Words: a title, a lyric, a chord symbol, a tempo, a bar number.
class TextPrim extends Prim {
  const TextPrim(
    this.text,
    this.x,
    this.y, {
    this.size = 1.7,
    this.style = TextStyleKind.plain,
    this.align = TextAlign.left,
    this.faded = false,
  });

  final String text;

  /// The left of the text, or its middle when [align] says so.
  final double x;

  /// The baseline.
  final double y;

  /// The height of a capital, in staff spaces.
  final double size;

  final TextStyleKind style;
  final TextAlign align;
  final bool faded;
}

enum TextStyleKind { plain, italic, bold, boldItalic }

/// Everything there is to draw, and how much room it takes.
class ScoreDrawing {
  const ScoreDrawing({
    required this.prims,
    required this.width,
    required this.height,
  });

  final List<Prim> prims;

  /// In staff spaces.
  final double width;
  final double height;

  static const empty = ScoreDrawing(prims: [], width: 0, height: 0);
}
