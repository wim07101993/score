import 'package:flutter/material.dart';

/// Asks to delete the set. What is played in it stays where it is.
class DeleteSetButton extends StatelessWidget {
  const DeleteSetButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline),
      label: const Text('Delete this set'),
    );
  }
}
