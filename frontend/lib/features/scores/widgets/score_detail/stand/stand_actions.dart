import 'package:flutter/material.dart';
import 'package:score/features/notation/view/score_view.dart';
import 'package:score/features/scores/widgets/score_detail/reading/reading_dialog.dart';
import 'package:score/features/scores/widgets/score_detail/score_reader.dart';
import 'package:score/features/scores/widgets/score_detail/stand/zoom_in_button.dart';
import 'package:score/features/scores/widgets/score_detail/stand/zoom_out_button.dart';

/// The score on the whole screen, with nothing over it but the way back,
/// its size, and how it is read.
///
/// The size is right there, since it is what is changed most while playing
/// — and a pinch does it as well. The key and the parts are a tap further
/// away, in a dialog over the music. Downloading and uploading are not here
/// at all: nobody does either from a music stand, and a button that does
/// is a button that gets pressed by accident between two songs.
class const StandActions({
  super.key,
  required final ScoreReader reader,
  final bool keptAsYourReading = false,
  final VoidCallback? onTouched,
}) extends StatelessWidget {
  void _zoomBy(double step) {
    reader.zoomBy(step);
    onTouched?.call();
  }

  void _changeView(ScoreView Function(ScoreView) change) {
    reader.changeView(change);
    onTouched?.call();
  }

  Future<void> _openReadingDialog(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => ReadingDialog(
      view: () => reader.view,
      parts: reader.parts,
      keptAsYourReading: keptAsYourReading,
      onChange: _changeView,
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (reader.musicXml == null) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZoomOutButton(onPressed: () => _zoomBy(-0.8)),
        ZoomInButton(onPressed: () => _zoomBy(0.8)),
        if (reader.view != null)
          IconButton(
            tooltip: 'How you read it',
            icon: const Icon(Icons.tune),
            onPressed: () => _openReadingDialog(context),
          ),
      ],
    );
  }
}
