import 'package:flutter/material.dart';

/// Leaves the set where it is, from the dialog that asks.
class KeepSetButton extends StatelessWidget {
  const KeepSetButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Keep it'));
  }
}
