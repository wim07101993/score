import 'package:flutter/material.dart';

/// One place later in the running order.
class MoveEntryDownButton extends StatelessWidget {
  const MoveEntryDownButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Move down',
      icon: const Icon(Icons.arrow_downward),
      onPressed: onPressed,
    );
  }
}
