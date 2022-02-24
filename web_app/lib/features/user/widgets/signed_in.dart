import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/change_notifiers/is_signed_in_notifier.dart';
import 'package:score/features/user/widgets/sign_in_screen.dart';

class SignedIn extends StatelessWidget {
  const SignedIn({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<IsSignedInNotifier>(builder: (context, isSignedIn, widget) {
      if (!isSignedIn.value) {
        return const SignInScreen();
      }
      return child;
    });
  }
}
