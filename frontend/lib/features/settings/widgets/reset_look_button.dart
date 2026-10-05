import 'package:flutter/material.dart';

/// Puts the page back to what it looks like out of the box.
class const ResetLookButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Reset'));
  }
}
