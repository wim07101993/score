import 'package:flutter/material.dart';

/// One place earlier in the running order.
class const MoveEntryUpButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Move up',
      icon: const Icon(Icons.arrow_upward),
      onPressed: onPressed,
    );
  }
}
