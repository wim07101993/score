import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:oidc/oidc.dart';

class LogOut extends BehaviourWithoutInput<void> {
  LogOut({
    required super.monitor,
    required this.userManager,
  });

  final OidcUserManager userManager;

  @override
  FutureOr<void> action(BehaviourTrack? track) => userManager.logout();
}
