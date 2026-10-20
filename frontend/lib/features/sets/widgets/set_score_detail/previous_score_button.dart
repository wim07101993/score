import 'package:flutter/material.dart';

/// Back one song in the set.
class const PreviousScoreButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'The score before this one',
      icon: const Icon(Icons.chevron_left),
      onPressed: onPressed,
    );
  }
}
