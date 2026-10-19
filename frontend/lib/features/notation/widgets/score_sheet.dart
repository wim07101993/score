import 'package:flutter/material.dart';
import 'package:score/features/notation/sheet_palette.dart';
import 'package:songbird_music_notation/songbird_music_notation.dart';

// The palette used to live here, and half the app still reasons about a score
// sheet and its colours together, so it is still handed out from here.
export 'package:score/features/notation/sheet_palette.dart';

/// A score, drawn.
///
/// The engraving is `songbird_music_notation`'s — this is the piece that says
/// what the app wants from it: the reader's lamp turned into a palette the
/// engraver understands.
class const ScoreSheet({
  super.key,
  required final ScoreController controller,
  final EdgeInsets padding = const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  ),

  /// The page and the ink on it. Null follows the app's own brightness, which
  /// is what a score drawn anywhere but the reading page does.
  ///
  /// Whatever is passed is a *pair*, and that is the point of taking a palette
  /// rather than two colours: nothing can hand this a page from one setting and
  /// ink from another.
  final SheetPalette? palette,
}) extends StatefulWidget {
  @override
  State<ScoreSheet> createState() => _ScoreSheetState();
}

class _ScoreSheetState extends State<ScoreSheet> {
  SheetPalette? _applied;
  ScoreController? _appliedTo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyPalette();
  }

  @override
  void didUpdateWidget(ScoreSheet old) {
    super.didUpdateWidget(old);
    _applyPalette();
  }

  void _applyPalette() {
    final palette =
        widget.palette ??
        SheetPalette.forBrightness(Theme.of(context).brightness);
    final controller = widget.controller;
    if (palette == _applied && identical(controller, _appliedTo)) {
      return;
    }
    _applied = palette;
    _appliedTo = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.style = _styleFor(palette);
      }
    });
  }

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
    return MusicScoreView(
      controller: widget.controller,
      padding: widget.padding,
    );
  }
}
