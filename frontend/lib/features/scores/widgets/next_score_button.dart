import 'package:flutter/material.dart';

/// On one song in the set.
class NextScoreButton extends StatelessWidget {
  const NextScoreButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'The score after this one',
      icon: const Icon(Icons.chevron_right),
      onPressed: onPressed,
    );
  }
}
