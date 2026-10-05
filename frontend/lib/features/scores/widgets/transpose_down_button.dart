import 'package:flutter/material.dart';

/// Reads the score a semitone lower than it is now.
class const TransposeDownButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'A semitone lower',
      icon: const Icon(Icons.remove),
      onPressed: onPressed,
    );
  }
}
