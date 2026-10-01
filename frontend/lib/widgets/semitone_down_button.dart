import 'package:flutter/material.dart';

/// One semitone down, beside the number it is counted in.
class SemitoneDownButton extends StatelessWidget {
  const SemitoneDownButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.remove),
      onPressed: onPressed,
    );
  }
}
