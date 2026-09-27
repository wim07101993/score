import 'package:flutter/material.dart';
import 'package:score/features/notation/view/score_view.dart';

/// How far the score is read from where it is written.
class TransposeSlider extends StatelessWidget {
  const TransposeSlider({
    super.key,
    required this.semitones,
    required this.onChanged,
  });

  final int semitones;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: semitones.toDouble(),
      min: minTransposition.toDouble(),
      max: maxTransposition.toDouble(),
      divisions: maxTransposition - minTransposition,
      label: '${semitones > 0 ? '+' : ''}$semitones',
      // Redrawing a score is expensive enough that doing it for every pixel of
      // a drag is not worth it: dragging moves the number and letting go
      // redraws.
      onChanged: (value) {},
      onChangeEnd: (value) => onChanged(value.round()),
    );
  }
}
