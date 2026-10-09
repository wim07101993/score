import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:score/features/auth/storage/auth_tokens.dart';
import 'package:score/router.dart';

/// Asks the player, over whatever page is open, whether to sign in.
class const SignInPromptDialog({
  required final AppRouter router,

  /// Signs in, the way the player asking to does. A function rather than the
  /// behaviour itself: signing in is what forgets the last user's sets, and
  /// the sets are sent with the tokens this asks for.
  required final Future<void> Function() signIn,
}) implements SignInPrompt {
  @override
  Future<SignInAnswer> ask() async {
    final context = router.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return SignInAnswer.couldNotAsk;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign in?'),
        content: const Text(
          'You are not signed in, so nothing can be fetched from or sent to'
          ' the server.'
          '${kIsWeb ? ' Signing in leaves this page for a moment.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
    if (yes != true) {
      return SignInAnswer.declined;
    }
    await signIn();
    return SignInAnswer.triedSigningIn;
  }
}
