import 'package:flutter/material.dart';

class CloseButton extends StatelessWidget {
  const CloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      iconSize: 48,
      onPressed: () => Navigator.of(context).pop(),
      icon: Icon(
        Icons.close,
        color: theme.textTheme.headline4?.color ?? Colors.black,
      ),
    );
  }
}
