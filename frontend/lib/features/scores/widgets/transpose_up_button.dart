import 'package:flutter/material.dart';

/// Reads the score a semitone higher than it is now.
class TransposeUpButton extends StatelessWidget {
  const TransposeUpButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'A semitone higher',
      icon: const Icon(Icons.add),
      onPressed: onPressed,
    );
  }
}
