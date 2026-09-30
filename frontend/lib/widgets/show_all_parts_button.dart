import 'package:flutter/material.dart';

/// Puts every part of the song back on this player's screen.
class ShowAllPartsButton extends StatelessWidget {
  const ShowAllPartsButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('show all'));
  }
}
