import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/score_detail/reading/reading_dialog.dart';
import 'package:score/features/scores/widgets/score_detail/score_view_controller.dart';
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
  required final ScoreViewController? controller,
  final bool keptAsYourReading = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZoomOutButton(onPressed: controller.zoomOut),
        ZoomInButton(onPressed: controller.zoomIn),
        IconButton(
          tooltip: 'How you read it',
          icon: const Icon(Icons.tune),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => ReadingDialog(
              controller: controller,
              keptAsYourReading: keptAsYourReading,
            ),
          ),
        ),
      ],
    );
  }
}
