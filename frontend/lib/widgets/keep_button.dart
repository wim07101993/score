import 'package:flutter/material.dart';

/// Leaves a set or a collection where it is, from the dialog that asks whether
/// to delete it.
class KeepButton extends StatelessWidget {
  const KeepButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Keep it'));
  }
}
