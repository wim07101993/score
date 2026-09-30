import 'package:flutter/material.dart';

/// Signs the user out of this device, and forgets their sets and collections.
class SignOutButton extends StatelessWidget {
  const SignOutButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: const Text('Sign out'),
    );
  }
}
