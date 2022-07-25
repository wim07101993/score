import 'package:flutter/material.dart';

class RemovableListItem extends StatelessWidget {
  const RemovableListItem({
    super.key,
    required this.child,
    required this.onRemove,
  });

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Expanded(child: child),
      IconButton(
        onPressed: onRemove,
        icon: Icon(
          Icons.remove_circle,
          color: theme.colorScheme.secondary,
        ),
      ),
    ]);
  }
}
