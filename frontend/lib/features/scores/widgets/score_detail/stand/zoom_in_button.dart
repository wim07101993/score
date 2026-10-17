import 'package:flutter/material.dart';

/// Draws the score a little bigger.
class const ZoomInButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Bigger',
      icon: const Icon(Icons.zoom_in),
      onPressed: onPressed,
    );
  }
}
