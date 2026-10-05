import 'package:flutter/material.dart';

/// Sends what has been typed about a set or a collection.
class const SaveButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Save'));
  }
}
