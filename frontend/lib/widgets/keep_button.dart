import 'package:flutter/material.dart';

/// Leaves a set or a collection where it is, from the dialog that asks whether
/// to delete it.
class const KeepButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Keep it'));
  }
}
