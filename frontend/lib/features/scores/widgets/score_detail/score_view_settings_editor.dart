import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/score_detail/part_selector.dart';
import 'package:score/features/scores/widgets/score_detail/reading/show_as_written_button.dart';
import 'package:score/features/scores/widgets/score_detail/score_view_controller.dart';
import 'package:score/features/scores/widgets/score_detail/transpose_buttons.dart';

class const ScoreViewSettingsEditor({
  super.key,
  required final ScoreViewController controller,
  final bool keptAsYourReading = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TransposeButtons(controller: controller),
        if (controller.parts.length > 1) ...[
          const SizedBox(height: 8),
          const Text('Instruments on screen'),
          const SizedBox(height: 4),
          PartSelector(controller: controller),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ShowAsWrittenButton(controller: controller),
            if (keptAsYourReading)
              Tooltip(
                message:
                    "Only you see this. What the band plays is the"
                    " owner's to say.",
                child: Text(
                  'Kept as how you read it',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
