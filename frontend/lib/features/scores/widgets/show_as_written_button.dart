import 'package:flutter/material.dart';

/// Puts the score back to the key and the parts it was written with.
class const ShowAsWrittenButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: const Text('Show as written'),
    );
  }
}
