import 'package:flutter/material.dart';

/// Opens the piece to play it, straight to the music.
class const OpenCollectionEntryButton({
  super.key,

  /// Null for a piece that has yet to be scanned: there is no score to open.
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Open'));
  }
}
