import 'package:flutter/material.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/scores/widgets/score_detail/score_view_controller.dart';

class const TransposeButtons({
  super.key,
  required final ScoreViewController controller,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.scoreController,
      builder: (context, _) {
        final semitones = controller.transposition;
        return Row(
          children: [
            const Text('Transpose'),
            const Spacer(),
            IconButton(
              tooltip: 'A semitone lower',
              icon: const Icon(Icons.remove),
              onPressed: semitones <= ScoreViewSettings.minTransposition
                  ? null
                  : () => controller.transposeBy(-1),
            ),
            SizedBox(
              width: 36,
              child: Text(
                '${semitones > 0 ? '+' : ''}$semitones',
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: 'A semitone higher',
              icon: const Icon(Icons.add),
              onPressed: semitones >= ScoreViewSettings.maxTransposition
                  ? null
                  : () => controller.transposeBy(1),
            ),
          ],
        );
      },
    );
  }
}
