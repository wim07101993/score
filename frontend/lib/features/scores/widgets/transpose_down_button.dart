import 'package:flutter/material.dart';

/// Reads the score a semitone lower than it is now.
class TransposeDownButton extends StatelessWidget {
  const TransposeDownButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'A semitone lower',
      icon: const Icon(Icons.remove),
      onPressed: onPressed,
    );
  }
}
