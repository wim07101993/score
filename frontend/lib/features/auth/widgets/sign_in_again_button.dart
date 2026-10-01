import 'package:flutter/material.dart';

/// Forgets the tokens and the roles this device is holding, and starts over.
class SignInAgainButton extends StatelessWidget {
  const SignInAgainButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: const Text('Sign in again'),
    );
  }
}
