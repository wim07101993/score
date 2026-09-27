import 'package:flutter/material.dart';

/// Puts the page back to what it looks like out of the box.
class ResetLookButton extends StatelessWidget {
  const ResetLookButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Reset'));
  }
}
