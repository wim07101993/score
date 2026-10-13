import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/auth/authentication_exception.dart';
import 'package:score/features/auth/behaviours/authenticate.dart';
import 'package:score/widgets/error_snack_bar.dart';

class const SignInButton({
  super.key,
}) extends StatefulWidget {
  @override
  State<SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<SignInButton> {
  bool _busy = false;

  Future<void> _signIn() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      switch (await GetIt.I<Authenticate>()(const AuthenticateParams())) {
        case Success():
          break;
        case Failed(
          reason: SignInCancelled(),
        ):
          break;
        case Failed(:final reason):
          messenger.showSnackBar(errorSnackBar('$reason'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _busy ? null : _signIn,
      child: const Text('Sign in'),
    );
  }
}
