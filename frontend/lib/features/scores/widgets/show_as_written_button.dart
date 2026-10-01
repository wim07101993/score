import 'package:flutter/material.dart';

/// Puts the score back to the key and the parts it was written with.
class ShowAsWrittenButton extends StatelessWidget {
  const ShowAsWrittenButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: const Text('Show as written'),
    );
  }
}
