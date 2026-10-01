import 'package:flutter/material.dart';

/// Draws the score a little smaller.
class ZoomOutButton extends StatelessWidget {
  const ZoomOutButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Smaller',
      icon: const Icon(Icons.zoom_out),
      onPressed: onPressed,
    );
  }
}
