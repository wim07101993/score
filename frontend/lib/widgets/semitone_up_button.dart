import 'package:flutter/material.dart';

/// One semitone up, beside the number it is counted in.
class const SemitoneUpButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.add),
      onPressed: onPressed,
    );
  }
}
