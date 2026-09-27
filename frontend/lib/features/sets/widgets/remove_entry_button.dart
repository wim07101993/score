import 'package:flutter/material.dart';

/// Takes the song out of the set.
class RemoveEntryButton extends StatelessWidget {
  const RemoveEntryButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Take out of the set',
      icon: const Icon(Icons.close),
      onPressed: onPressed,
    );
  }
}
