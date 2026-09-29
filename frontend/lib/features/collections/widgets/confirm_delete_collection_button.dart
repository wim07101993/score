import 'package:flutter/material.dart';

/// Says yes to deleting the collection, from the dialog that asks.
class ConfirmDeleteCollectionButton extends StatelessWidget {
  const ConfirmDeleteCollectionButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: const Text('Delete'));
  }
}
