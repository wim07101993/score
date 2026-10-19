import 'package:flutter/material.dart';

/// Opens the piece to play it, straight to the music.
class const OpenCollectionEntryButton({
  super.key,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Open'));
  }
}
