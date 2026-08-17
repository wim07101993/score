import 'package:flutter/material.dart';

/// Which slider is which, for anything that has to find one by name.
Key dialKey(String label) => Key('dial-$label');

/// One dial of the page's lighting.
class LookSlider extends StatelessWidget {
  const LookSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.readout,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String readout;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    // Named, so that a reader who cannot see the page hears which dial this is
    // rather than a number on its own.
    return Semantics(
      label: label,
      child: Slider(
        key: dialKey(label),
        value: value.clamp(min, max),
        min: min,
        max: max,
        label: readout,
        onChanged: onChanged,
      ),
    );
  }
}
