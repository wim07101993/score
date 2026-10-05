import 'package:flutter/material.dart';

/// Forgets the tokens and the roles this device is holding, and starts over.
class const SignInAgainButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: const Text('Sign in again'),
    );
  }
}
