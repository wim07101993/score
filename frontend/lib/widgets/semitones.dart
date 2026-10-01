import 'package:flutter/material.dart';
import 'package:score/features/notation/view/score_view.dart';
import 'package:score/widgets/semitone_down_button.dart';
import 'package:score/widgets/semitone_up_button.dart';

/// A number of semitones with a button either side: how far the band plays an
/// entry from where it is written, or how far one player reads it from there.
class Semitones extends StatelessWidget {
  const Semitones({
    super.key,
    required this.label,
    required this.tooltip,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String tooltip;
  final int value;
  final bool enabled;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          SemitoneDownButton(
            onPressed: enabled && value > minTransposition
                ? () => onChanged(value - 1)
                : null,
          ),
          SizedBox(
            width: 28,
            child: Text('${value > 0 ? '+' : ''}$value',
                textAlign: TextAlign.center),
          ),
          SemitoneUpButton(
            onPressed: enabled && value < maxTransposition
                ? () => onChanged(value + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
