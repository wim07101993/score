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
  Future<void> action() => _googleSignIn.signIn();

  @override
  Future<Failure> onFailed(dynamic e, StackTrace stacktrace) {
    return Future.value(const UnknownFailure());
  }
}
