import 'package:flutter/material.dart';

/// Signs the user out of this device, and forgets their sets and collections.
class const SignOutButton({
  super.key,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: const Text('Sign out'),
    );
  }
}
