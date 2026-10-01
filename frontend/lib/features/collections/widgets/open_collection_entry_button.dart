import 'package:flutter/material.dart';

/// Opens the piece to play it, straight to the music.
class OpenCollectionEntryButton extends StatelessWidget {
  const OpenCollectionEntryButton({
    super.key,
    required this.onPressed,
  });

  /// Null for a piece that has yet to be scanned: there is no score to open.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Open'));
  }
}
