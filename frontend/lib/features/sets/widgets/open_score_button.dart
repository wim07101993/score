import 'package:flutter/material.dart';

/// Opens the song, from where it sits in the running order.
class OpenScoreButton extends StatelessWidget {
  const OpenScoreButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Open'));
  }
}
