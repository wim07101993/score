import 'package:flutter/material.dart';

/// Takes the song out of the set.
class const RemoveEntryButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Take out of the set',
      icon: const Icon(Icons.close),
      onPressed: onPressed,
    );
  }
}
