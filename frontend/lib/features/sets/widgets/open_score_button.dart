import 'package:flutter/material.dart';

/// Opens the song, from where it sits in the running order.
class const OpenScoreButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Open'));
  }
}
