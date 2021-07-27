import 'package:core/core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LogInWithGoogle extends BehaviourWithoutInput<void> {
  LogInWithGoogle({
    required Logger errorLogger,
    required GoogleSignIn googleSignIn,
  })  : _googleSignIn = googleSignIn,
        super(errorLogger: errorLogger);

  final GoogleSignIn _googleSignIn;

  @override
  Future<void> action() async {
    final googleAccount = await _googleSignIn.signIn();
    if (googleAccount != null) {
      print(googleAccount);
      print(googleAccount.email);
      print(googleAccount.id);
    } else {
      print('not signed in');
    }
  }

  @override
  Future<Failure> onFailed(dynamic e, StackTrace stacktrace) {
    return Future.value(const UnknownFailure());
  }
}
