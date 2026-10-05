import 'package:flutter/material.dart';

/// Puts every part of the song back on this player's screen.
class const ShowAllPartsButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('show all'));
  }
}
