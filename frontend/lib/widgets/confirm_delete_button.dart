import 'package:flutter/material.dart';

/// Says yes to deleting a set or a collection, from the dialog that asks.
class ConfirmDeleteButton extends StatelessWidget {
  const ConfirmDeleteButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: const Text('Delete'));
  }
}
