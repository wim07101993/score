import 'package:flutter/material.dart';

/// Back one song in the set.
class PreviousScoreButton extends StatelessWidget {
  const PreviousScoreButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'The score before this one',
      icon: const Icon(Icons.chevron_left),
      onPressed: onPressed,
    );
  }
}
