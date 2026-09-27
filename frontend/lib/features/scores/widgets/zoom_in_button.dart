import 'package:flutter/material.dart';

/// Draws the score a little bigger.
class ZoomInButton extends StatelessWidget {
  const ZoomInButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Bigger',
      icon: const Icon(Icons.zoom_in),
      onPressed: onPressed,
    );
  }
}
