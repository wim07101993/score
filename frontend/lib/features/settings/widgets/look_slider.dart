import 'package:flutter/material.dart';

/// Which slider is which, for anything that has to find one by name.
Key dialKey(String label) => Key('dial-$label');

/// One dial of the page's lighting.
class const LookSlider({
  super.key,
  required final String label,
  required final double value,
  required final double min,
  required final double max,
  required final String readout,
  required final ValueChanged<double> onChanged,

  /// Called once the thumb is let go of, with where it was left.
  final ValueChanged<double>? onChangeEnd,
}) extends StatelessWidget {
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
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}
