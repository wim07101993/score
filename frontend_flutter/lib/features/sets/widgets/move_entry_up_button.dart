import 'package:flutter/material.dart';

/// One place earlier in the running order.
class MoveEntryUpButton extends StatelessWidget {
  const MoveEntryUpButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Move up',
      icon: const Icon(Icons.arrow_upward),
      onPressed: onPressed,
    );
  }
}
