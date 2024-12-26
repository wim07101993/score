import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:oidc/oidc.dart';

class LogIn extends BehaviourWithoutInput<OidcUser?> {
  LogIn({
    required super.monitor,
    required this.userManager,
  });

  final OidcUserManager userManager;

  @override
  FutureOr<OidcUser?> action(BehaviourTrack? track) {
    return userManager.loginAuthorizationCodeFlow();
  }
}
