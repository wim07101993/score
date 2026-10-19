import 'package:flutter/material.dart';

class const PerformButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Perform'),
    );
  }
}
