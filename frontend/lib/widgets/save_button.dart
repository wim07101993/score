import 'package:flutter/material.dart';

/// Sends what has been typed about a set or a collection.
class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Save'));
  }
}
