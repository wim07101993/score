import 'package:flutter/material.dart';

/// Asks to delete the set. What is played in it stays where it is.
class const DeleteSetButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline),
      label: const Text('Delete this set'),
    );
  }
}
