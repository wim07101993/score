import 'package:flutter/material.dart';

/// On one song in the set.
class const NextScoreButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'The score after this one',
      icon: const Icon(Icons.chevron_right),
      onPressed: onPressed,
    );
  }
}
