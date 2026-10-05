import 'package:flutter/material.dart';

/// Draws the score a little smaller.
class const ZoomOutButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Smaller',
      icon: const Icon(Icons.zoom_out),
      onPressed: onPressed,
    );
  }
}
