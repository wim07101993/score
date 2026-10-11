import 'package:flutter/material.dart';
import 'package:score/features/auth/widgets/sign_in_button.dart';

class const SignedOut() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text('You are not signed in', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Sign in to see your scores and sets on this device.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const SignInButton(),
          ],
        ),
      ),
    );
  }
}
