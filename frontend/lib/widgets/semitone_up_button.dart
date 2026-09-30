import 'package:flutter/material.dart';

/// One semitone up, beside the number it is counted in.
class SemitoneUpButton extends StatelessWidget {
  const SemitoneUpButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.add),
      onPressed: onPressed,
    );
  }
}
