import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'layout/engine.dart';
import 'musicxml/model.dart';
import 'musicxml/parser.dart';
import 'render/primitives.dart';
import 'render/score_painter.dart';
import 'view/musicxml_view.dart';
import 'view/score_view.dart';

/// Paper, and the ink on it.
///
/// The two are chosen together and never apart. Paper that followed the theme
/// while the ink did not — or the other way round — is pale grey notes on a
/// white page, which is the one way this can go wrong and did.
@immutable
class SheetPalette {
  const SheetPalette({
    required this.paper,
    required this.ink,
    required this.fadedInk,
  });

  /// The page.
  final Color paper;

  /// Everything drawn on it: staff lines, noteheads, stems, words.
  final Color ink;

  /// A grace note, which leans on the note after it and is drawn lighter to
  /// say so.
  final Color fadedInk;

  /// A page with a lamp on it.
  ///
  /// [brightness] is what the page gives off, as a share of a white one: 1 is
  /// paper under a working light, and the numbers below that are the same page
  /// with the lamp turned down. It is the reader's to set, and it is the whole
  /// of what "dark" means here — see [dark].
  ///
  /// It is a share of *light*, not of the numbers a colour is written with. Half
  /// way down this scale is a page that throws half the light, which is what an
  /// eye reckons by; the sRGB grey that does that is `#BCBCBC`, nowhere near the
  /// halfway `#808080`. So the scale is worked in luminance and turned back into
  /// a colour at the end, and a reader dragging it feels an even dimming rather
  /// than a lot of nothing at one end and a cliff at the other.
  ///
  /// [warmth] is how far from grey the page is, from 0 for neutral to 1 for
  /// something like paper by candlelight. It costs almost no light — it is the
  /// blue that is taken away — so it can be had at any brightness. Ink takes a
  /// little of it too: a black that stays blue-black on a warm page reads as a
  /// hole in it.
  factory SheetPalette.lamp({required double brightness, double warmth = 0}) {
    final lamp = brightness.clamp(dimmest, full);
    final warm = warmth.clamp(0.0, 1.0);
    final grey = _greyGiving(lamp);

    Color shift(double r, double g, double b) => Color.fromARGB(
          255,
          (grey + r * warm).round().clamp(0, 255),
          (grey + g * warm).round().clamp(0, 255),
          (grey + b * warm).round().clamp(0, 255),
        );

    // Held at a near-black rather than black, and let all the way down to black
    // only as the page comes up to full: ink darker than the darkest thing a
    // dimmed screen can show is ink nobody gains anything from.
    Color inkAt(double r, double g, double b) => Color.fromARGB(
          255,
          ((r + 9 * warm) * (1 - lamp)).round().clamp(0, 255),
          ((g + 3 * warm) * (1 - lamp)).round().clamp(0, 255),
          ((b - 11 * warm) * (1 - lamp)).round().clamp(0, 255),
        );

    final ink = inkAt(17, 19, 22);
    return SheetPalette(
      // Balanced so that warming the page does not also brighten it: red is
      // worth about three times as much light as blue, so nine points of red
      // buys back the twenty-six taken out of blue. Two dials that moved each
      // other would be two dials nobody could set.
      paper: shift(9, 0, -26),
      ink: ink,
      // A dimmer page has less room between its darkest and its lightest, so a
      // grace note gives up less of what there is.
      fadedInk: ink.withValues(alpha: 0.62 - 0.07 * lamp),
    );
  }

  /// The dimmest the page is allowed to go.
  ///
  /// Below this the ink cannot stay clear of the page: black on a page this dim
  /// is already down at about four to one, and a staff line is a hairline.
  static const double dimmest = 0.18;

  /// Paper under a working light.
  static const double full = 1.0;

  /// Where the lamp starts when the app is dark and the reader has not said
  /// otherwise, with a little warmth in it, which most people want at night and
  /// nobody misses in the dark.
  static const double night = 0.29;
  static const double nightWarmth = 0.3;

  /// The sRGB grey that gives off [luminance] of what white gives off.
  static double _greyGiving(double luminance) {
    final v = luminance <= 0.0031308
        ? luminance * 12.92
        : 1.055 * math.pow(luminance, 1 / 2.4) - 0.055;
    return (v * 255).clamp(0.0, 255.0);
  }

  /// Ink on paper, the way a score is printed and the way it is read in a lit
  /// room. The lamp full up, and no warmth in it.
  static final light = SheetPalette.lamp(brightness: full);

  /// The same page in a dark room — which is the same page, turned down.
  ///
  /// **Not an inversion.** A score in the dark is still ink on paper; what
  /// changes is how much light the paper is throwing at the reader. Every
  /// version of this that swapped them round — light marks on a dark page — was
  /// wrong in the same way, and no amount of moving the two tones apart or
  /// together fixed it, because the problem was never the distance between them.
  ///
  /// A screen is not paper. Paper is lit by the room and gives back a fraction
  /// of what falls on it; a screen makes its own light and pushes it at the
  /// reader. In a dark room the eye opens up, and then anything bright on that
  /// screen *blooms* — which is exactly what a white notehead is, and a white
  /// notehead is also the thing being looked at. Dark marks cannot bloom. They
  /// have no light to give.
  ///
  /// So the page is dimmed to about a third of what a white one puts out, and
  /// the notes stay dark, as notes are. What is left is a page that can be read
  /// for the length of a rehearsal in a room with the lights off, and that is
  /// still recognisably the score — the same drawing, on paper someone has
  /// turned the lamp down on.
  ///
  /// The two are nearer together than black on white — about six to one against
  /// twenty-one — because a dimmer page has less room between its darkest and
  /// its lightest, and because there is no longer any need to shout: since
  /// `ScorePainter` began putting hairlines on whole pixels, a staff line is the
  /// ink rather than a half-covered grey, and it holds at this distance.
  ///
  /// This is only where the lamp *starts* in the dark. Where it ends up is the
  /// reader's, in the settings, because how dim a page wants to be is a question
  /// about a room and not about an app.
  static final dark =
      SheetPalette.lamp(brightness: night, warmth: nightWarmth);

  /// The page as it is read under [brightness] — the app's, which is the
  /// system's unless the reader has said otherwise in the settings.
  static SheetPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  bool operator ==(Object other) =>
      other is SheetPalette &&
      other.paper == paper &&
      other.ink == ink &&
      other.fadedInk == fadedInk;

  @override
  int get hashCode => Object.hash(paper, ink, fadedInk);
}

/// A score, drawn.
///
/// It is handed the document as it was uploaded and the way it is being looked
/// at, and works out the rest. Transposing and hiding a part are applied to the
/// document on the way in, which is the same road the downloaded file takes —
/// so what is on screen and what comes out of the download button are the same
/// score, worked out once.
class ScoreSheet extends StatefulWidget {
  const ScoreSheet({
    super.key,
    required this.musicXml,
    this.view,
    this.space = 7.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.controller,
    this.palette,
  });

  /// The score as it was uploaded. Never written to.
  final String musicXml;

  /// The page and the ink on it. Null follows the app's own brightness, which
  /// is what a score drawn anywhere but the reading page does.
  ///
  /// Whatever is passed is a *pair*, and that is the point of taking a palette
  /// rather than two colours: nothing can hand this a page from one setting and
  /// ink from another.
  final SheetPalette? palette;

  /// How it is being looked at. Null is the score as it was written.
  final ScoreView? view;

  /// What one staff space is worth in logical pixels — the zoom.
  final double space;

  final EdgeInsets padding;

  final ScrollController? controller;

  @override
  State<ScoreSheet> createState() => _ScoreSheetState();
}

class _ScoreSheetState extends State<ScoreSheet> {
  /// The score as it is being looked at, parsed. Reading and transposing a
  /// document of a few hundred kilobytes is not something to do on every frame,
  /// so it is kept until what it was made from changes.
  MusicXmlScore? _score;
  Object? _failure;

  ScoreDrawing? _drawing;
  double _drawnWidth = -1;
  double _drawnSpace = -1;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(ScoreSheet old) {
    super.didUpdateWidget(old);
    if (old.musicXml != widget.musicXml || old.view != widget.view) {
      _read();
    }
    if (old.space != widget.space) {
      _drawing = null;
    }
  }

  void _read() {
    _drawing = null;
    try {
      _score = parseMusicXmlDocument(
        documentForView(widget.musicXml, widget.view),
      );
      _failure = null;
    } catch (error) {
      _score = null;
      _failure = error;
    }
  }

  ScoreDrawing _drawingFor(double widthSp) {
    final held = _drawing;
    if (held != null && _drawnWidth == widthSp && _drawnSpace == widget.space) {
      return held;
    }

    final score = _score;
    if (score == null) {
      return ScoreDrawing.empty;
    }

    final drawing = layoutScore(score, LayoutOptions(width: widthSp));
    _drawing = drawing;
    _drawnWidth = widthSp;
    _drawnSpace = widget.space;
    return drawing;
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    if (failure != null) {
      return _Failure(failure: failure);
    }

    final theme = Theme.of(context);
    final palette =
        widget.palette ?? SheetPalette.forBrightness(theme.brightness);

    return ColoredBox(
      color: palette.paper,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth -
              widget.padding.left -
              widget.padding.right;
          if (width <= 0) {
            return const SizedBox.shrink();
          }

          final widthSp = width / widget.space;
          final drawing = _drawingFor(widthSp);

          return SingleChildScrollView(
            controller: widget.controller,
            padding: widget.padding,
            child: CustomPaint(
              size: Size(width, drawing.height * widget.space),
              painter: ScorePainter(
                drawing: drawing,
                space: widget.space,
                ink: palette.ink,
                fadedInk: palette.fadedInk,
                devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                textFont: theme.textTheme.bodyMedium?.fontFamily,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.failure});

  final Object failure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 40),
            const SizedBox(height: 12),
            Text('This score could not be read.',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '$failure',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
