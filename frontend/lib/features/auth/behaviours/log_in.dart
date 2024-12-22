import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:oidc/oidc.dart';

class LogIn extends Behaviour<OidcUserManager, OidcUser?> {
  LogIn({
    required super.monitor,
  });

  @override
  FutureOr<OidcUser?> action(
    OidcUserManager userManager,
    BehaviourTrack? track,
  ) {
    return userManager.loginAuthorizationCodeFlow();
  }
}
