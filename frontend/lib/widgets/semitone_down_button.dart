import 'package:flutter/material.dart';

/// One semitone down, beside the number it is counted in.
class const SemitoneDownButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.remove),
      onPressed: onPressed,
    );
  }
}
