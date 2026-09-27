import 'package:flutter/material.dart';

/// Keeps how this player reads the song against the set.
class SaveMyViewButton extends StatelessWidget {
  const SaveMyViewButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Only you see this. What the band plays is the owner's to say.",
      child: FilledButton.tonal(
        onPressed: onPressed,
        child: const Text('Save as how I read it'),
      ),
    );
  }
}
