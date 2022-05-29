import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Logout extends BehaviourWithoutInput<void> {
  Logout({
    required this.auth,
    super.monitor,
  });

  final FirebaseAuth auth;

  @override
  Future<void> action(BehaviourTrack? track) => auth.signOut();

  @override
  String get description => 'logging out';

  @override
  FutureOr<Exception> onCatch(
      Object e, StackTrace stacktrace, BehaviourTrack? track) {
    return Exception();
  }
}
