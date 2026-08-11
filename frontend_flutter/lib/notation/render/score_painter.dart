import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'primitives.dart';

/// Drawing what the layout worked out.
///
/// This does nothing but put the primitives on a canvas at a scale. Every
/// decision about where anything goes was made by the layout, in staff spaces;
/// all that happens here is a multiplication, which is what makes zooming cost
/// nothing but a repaint.

/// The font every notehead, clef, rest and accidental is set in.
const String musicFont = 'Bravura';

/// A glyph is designed on an em of four staff spaces, so this is what a staff
/// space is worth in font size.
const double emPerSpace = 4.0;

class ScorePainter extends CustomPainter {
  ScorePainter({
    required this.drawing,
    required this.space,
    required this.ink,
    required this.fadedInk,
    this.devicePixelRatio = 1.0,
    this.textFont,
  });

  final ScoreDrawing drawing;

  /// What one staff space is worth in logical pixels.
  final double space;

  final Color ink;
  final Color fadedInk;

  /// How many of the screen's own pixels there are to a logical one.
  ///
  /// The layout works in staff spaces and does not know or care, but the
  /// thinnest things on a score land on the screen at about the size of a single
  /// pixel, and where a line of that size *falls* decides whether it is drawn as
  /// a line or as a smear. See [_snapped].
  final double devicePixelRatio;

  /// What words are set in. The music font has letters of its own, but they are
  /// meant for dynamics rather than for lyrics.
  final String? textFont;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = ink
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final prim in drawing.prims) {
      switch (prim) {
        case LinePrim():
          _line(canvas, prim, fill);
        case FillPrim():
          _fill(canvas, prim, fill);
        case CurvePrim():
          _curve(canvas, prim, fill);
        case GlyphPrim():
          _glyph(canvas, prim);
        case TextPrim():
          _text(canvas, prim);
      }
    }
  }

  /// An edge moved to the nearest pixel the screen actually has.
  ///
  /// A staff line is an eighth of a staff space thick, which at a readable zoom
  /// is about one pixel — and a one-pixel line that falls across the boundary
  /// between two pixels is not drawn as a line at all. It is drawn as two rows
  /// of half-covered pixels, and a half-covered pixel is half ink and half page.
  ///
  /// On white that survives: half of black on white is a grey that still reads
  /// as a line, which is why a score has looked right for as long as this has
  /// been wrong. On a dark page it does not. The noteheads are shapes several
  /// pixels across and land at full ink; the staff lines land at half; and half
  /// way between a near-black page and a near-white ink is a mid grey, so the
  /// notes stay crisp while the staff they sit on turns to smoke. That is the
  /// whole of why a dark score reads worse than a light one — not the colours,
  /// which are the same distance apart either way.
  ///
  /// So a hairline is put where the screen can draw it: both edges to a whole
  /// pixel, and never thinner than one. It costs a fraction of a pixel of
  /// position — at five lines to a staff the spacing can come out a pixel uneven
  /// — and buys every line its edge back, on both pages.
  double _snapped(double edge) =>
      (edge * devicePixelRatio).roundToDouble() / devicePixelRatio;

  /// [from]–[to] moved onto whole pixels, keeping at least one between them.
  (double, double) _hairline(double from, double to) {
    final start = _snapped(from);
    final end = _snapped(to);
    if (end - start < 1 / devicePixelRatio) {
      return (start, start + 1 / devicePixelRatio);
    }
    return (start, end);
  }

  void _line(Canvas canvas, LinePrim prim, Paint paint) {
    // A line of a given thickness is drawn as the rectangle it is, rather than
    // as a stroke: a staff line is a shape on the page with a top and a bottom,
    // and drawing it as a stroke would put half of it on either side of a
    // coordinate that means the middle of it.
    final half = prim.thickness * space / 2;
    if (prim.y1 == prim.y2) {
      final (top, bottom) =
          _hairline(prim.y1 * space - half, prim.y1 * space + half);
      canvas.drawRect(
        Rect.fromLTRB(prim.x1 * space, top, prim.x2 * space, bottom),
        paint,
      );
      return;
    }
    if (prim.x1 == prim.x2) {
      final (left, right) =
          _hairline(prim.x1 * space - half, prim.x1 * space + half);
      canvas.drawRect(
        Rect.fromLTRB(left, prim.y1 * space, right, prim.y2 * space),
        paint,
      );
      return;
    }

    canvas.drawLine(
      Offset(prim.x1 * space, prim.y1 * space),
      Offset(prim.x2 * space, prim.y2 * space),
      Paint()
        ..color = paint.color
        ..strokeWidth = prim.thickness * space
        ..isAntiAlias = true,
    );
  }

  void _fill(Canvas canvas, FillPrim prim, Paint paint) {
    if (prim.points.isEmpty) {
      return;
    }
    final path = Path()
      ..moveTo(prim.points.first.dx * space, prim.points.first.dy * space);
    for (final point in prim.points.skip(1)) {
      path.lineTo(point.dx * space, point.dy * space);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _curve(Canvas canvas, CurvePrim prim, Paint paint) {
    final from = Offset(prim.from.dx * space, prim.from.dy * space);
    final to = Offset(prim.to.dx * space, prim.to.dy * space);
    final middle = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);

    // A quadratic curve passes half as far as its control point, so the pull
    // is doubled to arch by what was asked for. The two edges differ by twice
    // the thickness for the same reason, which is what makes it thin at the
    // ends and thick in the middle the way a drawn slur is.
    final outer = Offset(middle.dx, middle.dy + prim.bow * 2 * space);
    final inner = Offset(
      outer.dx,
      outer.dy + 2 * prim.thickness * space * (prim.bow < 0 ? 1 : -1),
    );

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(outer.dx, outer.dy, to.dx, to.dy)
      ..quadraticBezierTo(inner.dx, inner.dy, from.dx, from.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _glyph(Canvas canvas, GlyphPrim prim) {
    final painter = _cachedGlyph(
      prim.glyph.char,
      emPerSpace * space * prim.scale,
      prim.faded ? fadedInk : ink,
    );

    // The glyph's own origin sits on its baseline, which is what every
    // measurement in the metadata is taken from.
    final baseline =
        painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    painter.paint(
      canvas,
      Offset(prim.x * space, prim.y * space - baseline),
    );
  }

  void _text(Canvas canvas, TextPrim prim) {
    final painter = _cachedText(
      prim.text,
      prim.size * space,
      prim.faded ? fadedInk : ink,
      prim.style,
      textFont,
    );

    final baseline =
        painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);

    final dx = switch (prim.align) {
      TextAlign.center => prim.x * space - painter.width / 2,
      TextAlign.right => prim.x * space - painter.width,
      _ => prim.x * space,
    };

    painter.paint(canvas, Offset(dx, prim.y * space - baseline));
  }

  @override
  bool shouldRepaint(ScorePainter old) =>
      old.drawing != drawing ||
      old.space != space ||
      old.ink != ink ||
      old.fadedInk != fadedInk ||
      // A window dragged to a screen of a different density has to be drawn
      // again: where the hairlines fall is worked out from this.
      old.devicePixelRatio != devicePixelRatio;
}

// ---------------------------------------------------------------------------
// KEEPING THE SET TEXT
// ---------------------------------------------------------------------------

/// A score is thousands of glyphs and is redrawn on every scroll, so laying
/// each one out again every time is the difference between a score that moves
/// and one that stutters. There are only so many distinct glyphs at only so
/// many sizes, so they are kept.
final Map<String, TextPainter> _glyphCache = {};
final Map<String, TextPainter> _textCache = {};

/// How many laid-out pieces of text to keep. A page of music is a few hundred
/// distinct ones; this is enough for several sizes of them and small enough
/// that a long session does not grow without end.
const int _cacheLimit = 3000;

TextPainter _cachedGlyph(String char, double size, Color color) {
  final key = '$char|${size.toStringAsFixed(2)}|${color.toARGB32()}';
  final held = _glyphCache[key];
  if (held != null) {
    return held;
  }

  final painter = TextPainter(
    text: TextSpan(
      text: char,
      style: TextStyle(
        fontFamily: musicFont,
        fontSize: size,
        color: color,
        height: 1.0,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout();

  if (_glyphCache.length >= _cacheLimit) {
    _glyphCache.clear();
  }
  _glyphCache[key] = painter;
  return painter;
}

TextPainter _cachedText(
  String text,
  double size,
  Color color,
  TextStyleKind kind,
  String? font,
) {
  final key = '$text|${size.toStringAsFixed(2)}|${color.toARGB32()}|$kind|$font';
  final held = _textCache[key];
  if (held != null) {
    return held;
  }

  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: font,
        fontSize: size,
        color: color,
        height: 1.0,
        fontWeight: kind == TextStyleKind.bold || kind == TextStyleKind.boldItalic
            ? FontWeight.w600
            : FontWeight.normal,
        fontStyle:
            kind == TextStyleKind.italic || kind == TextStyleKind.boldItalic
                ? FontStyle.italic
                : FontStyle.normal,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
    maxLines: 1,
  )..layout();

  if (_textCache.length >= _cacheLimit) {
    _textCache.clear();
  }
  _textCache[key] = painter;
  return painter;
}
