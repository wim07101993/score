import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:oidc/oidc.dart';

class LogIn extends Behaviour<LoginParams, OidcUser?> {
  LogIn({
    required super.monitor,
    required this.userManager,
  });

  final OidcUserManager userManager;

  @override
  FutureOr<OidcUser?> action(LoginParams input, BehaviourTrack? track) {
    return userManager.loginAuthorizationCodeFlow(
      uiLocalesOverride: [input.locale],
    );
  }
}

class LoginParams {
  const LoginParams({
    required this.locale,
  });

  final String locale;
}
