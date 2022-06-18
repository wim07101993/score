import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterfire_ui/auth.dart' as firebase;
import 'package:flutterfire_ui/auth.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';
import 'package:score/shared/data/firebase/provider_configurations.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return firebase.SignInScreen(
      providerConfigs: context.read<ProviderConfigurations>()(),
      actions: [AuthStateChangeAction(onAuthStateChanged)],
    );
  }

  void onAuthStateChanged(BuildContext context, Object? state) {
    if (state is AuthFailed) {
      final exception = state.exception;
      if (exception is PlatformException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(exception.toString())),
        );
      }
    } else if (state is SignedIn) {
      context.read<UserNotifier>().refreshUser();
    }
  }
}
