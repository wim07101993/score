import 'package:flutter/material.dart';

/// Says yes to deleting a set or a collection, from the dialog that asks.
class const ConfirmDeleteButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: const Text('Delete'));
  }
}
