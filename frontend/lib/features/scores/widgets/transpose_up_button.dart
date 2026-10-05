import 'package:flutter/material.dart';

/// Reads the score a semitone higher than it is now.
class const TransposeUpButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'A semitone higher',
      icon: const Icon(Icons.add),
      onPressed: onPressed,
    );
  }
}
