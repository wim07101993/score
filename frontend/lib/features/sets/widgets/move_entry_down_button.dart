import 'package:flutter/material.dart';

/// One place later in the running order.
class const MoveEntryDownButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Move down',
      icon: const Icon(Icons.arrow_downward),
      onPressed: onPressed,
    );
  }
}
