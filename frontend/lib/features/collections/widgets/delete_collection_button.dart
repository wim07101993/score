import 'package:flutter/material.dart';

/// Asks to delete the collection. The scores in it stay where they are.
class const DeleteCollectionButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline),
      label: const Text('Delete this collection'),
    );
  }
}
