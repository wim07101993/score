import 'package:flutter/material.dart';

/// Leaves the collection where it is, from the dialog that asks.
class KeepCollectionButton extends StatelessWidget {
  const KeepCollectionButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: const Text('Keep it'));
  }
}
