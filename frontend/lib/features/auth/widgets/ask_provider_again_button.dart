import 'package:flutter/material.dart';

/// Asks the provider who this is, again.
class const AskProviderAgainButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      child: const Text('Ask the provider again'),
    );
  }
}
