import 'package:flutter/material.dart';

/// Asks the provider who this is, again.
class AskProviderAgainButton extends StatelessWidget {
  const AskProviderAgainButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      child: const Text('Ask the provider again'),
    );
  }
}
