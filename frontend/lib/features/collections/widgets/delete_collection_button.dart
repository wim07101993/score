import 'package:flutter/material.dart';

/// Asks to delete the collection. The scores in it stay where they are.
class DeleteCollectionButton extends StatelessWidget {
  const DeleteCollectionButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline),
      label: const Text('Delete this collection'),
    );
  }
}
