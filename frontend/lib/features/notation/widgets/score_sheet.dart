import 'package:flutter/material.dart';
import 'package:score/features/notation/parts.dart';
import 'package:score/features/notation/sheet_palette.dart';
import 'package:score/features/notation/view/score_view.dart';
import 'package:songbird_music_notation/songbird_music_notation.dart';
import 'package:songbird_score/songbird_score.dart';

// The palette used to live here, and half the app still reasons about a score
// sheet and its colours together, so it is still handed out from here.
export 'package:score/features/notation/sheet_palette.dart';

/// A score, drawn.
///
/// It is handed the document as it was uploaded and the way it is being looked
/// at, and works out the rest. The engraving is
/// `songbird_music_notation`'s — this is the piece that says what the app
/// wants from it: the document read once, the view kept in step with the
/// score on screen, and the reader's lamp turned into a palette the engraver
/// understands.
///
/// Transposing and hiding a part are asked of the score itself rather than
/// applied to the document on the way in, so the file the app holds stays the
/// one that was uploaded. The download takes the same two steps on a score of
/// its own (`musicXmlForView`), which is why what is on screen and what comes
/// out of the download button agree.
class ScoreSheet extends StatefulWidget {
  const ScoreSheet({
    super.key,
    required this.musicXml,
    this.view,
    this.space = 7.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.palette,
    this.onNoteTapped,
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

  /// Called with whatever was clicked, for a page that wants to know.
  final void Function(LayoutHit hit)? onNoteTapped;

  @override
  State<ScoreSheet> createState() => _ScoreSheetState();
}

class _ScoreSheetState extends State<ScoreSheet> {
  ScoreController? _controller;

  /// Why the score could not be read, if it could not be.
  Object? _error;

  /// What the controller has already been told, so that a rebuild which
  /// changes neither does not ask it to transpose the score again.
  ScoreView? _applied;

  @override
  void didUpdateWidget(ScoreSheet old) {
    super.didUpdateWidget(old);

    // A different document is a different score, and everything else follows
    // from it. Anything short of that is asked of the controller in place:
    // re-reading to change a colour would engrave the whole score again.
    if (widget.musicXml != old.musicXml) {
      _read();
      return;
    }

    final controller = _controller;
    if (controller == null) return;

    if (widget.space != old.space) {
      controller.baseStaffSpace = widget.space;
    }
    if (widget.palette != old.palette) {
      controller.style = _styleFor(_paletteFor(context));
    }
    _syncView(controller);
  }

  /// Where the score is first read, rather than in `initState`.
  ///
  /// A sheet without a palette of its own is drawn in the app's own
  /// brightness, and a theme is a dependency rather than an argument: asking
  /// for one before the dependencies are in is not allowed, and the first
  /// engraving needs to know what colour it is.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null && _error == null) {
      _read();
      return;
    }
    if (widget.palette == null) {
      _controller?.style = _styleFor(_paletteFor(context));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _read() {
    _controller?.dispose();
    _controller = null;
    _applied = null;

    // Only the reading is caught. A score that cannot be read is a thing the
    // reader is told about; anything that goes wrong after it has been read is
    // a fault in this app, and swallowing it into "could not be read" would
    // hide it behind a message about somebody else's file.
    final Score score;
    try {
      score = parseMusicXml(widget.musicXml);
    } catch (error) {
      _error = error;
      if (mounted) setState(() {});
      return;
    }

    _giveEveryPartItsOwnId(score);
    final controller = ScoreController(
      score: score,
      baseStaffSpace: widget.space,
      style: _styleFor(_paletteFor(context)),
    );
    _syncView(controller);
    _controller = controller;
    _error = null;

    if (mounted) setState(() {});
  }

  /// Puts the controller where the view says, and nowhere else.
  ///
  /// Transposing is a step rather than a setting — the score is moved by an
  /// interval, not told what key to be in — so going from down a tone to up a
  /// third means putting it back first. The controller knows how far it has
  /// been moved, which is what makes that one call rather than bookkeeping
  /// here.
  void _syncView(ScoreController controller) {
    final view = widget.view;
    if (view == _applied) return;
    _applied = view;

    // By place, the way the download matches them. The controller itself
    // hides by the part's id, which is only the same thing because every part
    // was given an id of its own when the score was read.
    final refs = readParts(controller.score);
    for (var index = 0; index < controller.score.parts.length; index++) {
      if (index >= refs.length) break;
      controller.setPartVisible(
        controller.score.parts[index],
        view == null || !view.isHidden(refs[index].id),
      );
    }

    final wanted = view?.transposition ?? 0;
    controller.resetTransposition();
    if (wanted != 0) controller.transposeBySemitones(wanted);
  }

  /// Renames every part whose id is empty or taken to the one [readParts]
  /// names it by.
  ///
  /// The controller hides a part by its id, so two parts that share one would
  /// come and go together, while the view and the download both tell them
  /// apart by their place. This score is only ever drawn, never written out,
  /// so the name it gets here goes nowhere.
  static void _giveEveryPartItsOwnId(Score score) {
    final refs = readParts(score);
    for (var index = 0; index < score.parts.length; index++) {
      final part = score.parts[index];
      final id = refs[index].id;
      if (part.id == id) continue;
      score.parts[index] = Part(
        id: id,
        name: part.name,
        measures: part.measures,
        abbreviation: part.abbreviation,
        nameDisplay: part.nameDisplay,
        abbreviationDisplay: part.abbreviationDisplay,
        instruments: part.instruments,
        midiInstruments: part.midiInstruments,
        spanners: part.spanners,
        printName: part.printName,
        printAbbreviation: part.printAbbreviation,
      );
    }
  }

  SheetPalette _paletteFor(BuildContext context) =>
      widget.palette ??
      SheetPalette.forBrightness(Theme.of(context).brightness);

  /// The reader's lamp, as the engraver has it.
  ///
  /// The document's own colours are refused: a MusicXML exporter writes black
  /// into a file far more often than anyone means it to be looked at, and a
  /// black note on a dimmed page is a note nobody can see. The palette is the
  /// one thing deciding what the ink is.
  EngravingStyle _styleFor(SheetPalette palette) => EngravingStyle(
        colors: NotationColors(
          ink: palette.ink,
          staffLines: palette.ink,
          editorial: palette.fadedInk,
          background: palette.paper,
          honourSourceColors: false,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'This score could not be read: $error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MusicScoreView(
      controller: controller,
      padding: widget.padding,
      onTapElement: widget.onNoteTapped,
    );
  }
}
