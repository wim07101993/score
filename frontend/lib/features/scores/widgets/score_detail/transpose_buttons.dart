import 'package:flutter/material.dart';
import 'package:score/features/scores/models/score_view_settings.dart';

class const TransposeButtons({
  super.key,
  required final ValueNotifier<int> controller,
}) extends StatelessWidget {
  void transposeDown() {
    if (controller.value <= ScoreViewSettings.minTransposition) {
      return;
    }
    controller.value -= 1;
  }

  void transposeUp() {
    if (controller.value >= ScoreViewSettings.maxTransposition) {
      return;
    }
    controller.value += 1;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, semitones, _) => Row(
        children: [
          const Text('Transpose'),
          const Spacer(),
          IconButton(
            tooltip: 'A semitone lower',
            icon: const Icon(Icons.remove),
            onPressed: transposeDown,
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
            onPressed: transposeUp,
          ),
        ],
      ),
    );
  }
}
