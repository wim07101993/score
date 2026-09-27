import 'package:flutter/material.dart';

/// Says yes to deleting the set, from the dialog that asks.
class ConfirmDeleteSetButton extends StatelessWidget {
  const ConfirmDeleteSetButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: const Text('Delete'));
  }
}
