import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:provider/provider.dart';
import 'package:score/data/firebase/provider_configurations.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';

class SignInPage extends Page {
  const SignInPage({
    LocalKey? key,
  }) : super(key: key, name: 'login');

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (context) => SignInScreen(
        providerConfigs: context.read<ProviderConfigurations>()(),
        actions: [AuthStateChangeAction(onAuthStateChanged)],
      ),
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
      final user = state.user;
      context.read<UserNotifier>().user =
          user == null ? null : User.fromFirebase(user);
    }
  }
}
