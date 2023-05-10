import 'package:behaviour/behaviour.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Logout extends BehaviourWithoutInput<void> {
  Logout({
    super.monitor,
    required this.firebaseAuth,
  });

  final FirebaseAuth firebaseAuth;

  @override
  Future<void> action(BehaviourTrack? track) {
    return firebaseAuth.signOut();
  }
}
