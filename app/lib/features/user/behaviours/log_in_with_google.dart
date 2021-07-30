import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:score/features/user/behaviours/credential_converter.dart';

class LogInWithGoogle extends BehaviourWithoutInput<void> {
  LogInWithGoogle({
    required Logger errorLogger,
    required GoogleSignIn googleSignIn,
    required FirebaseAuth firebaseAuth,
    required CredentialConverter credentialConverter,
  })  : _googleSignIn = googleSignIn,
        _firebaseAuth = firebaseAuth,
        _credentialConverter = credentialConverter,
        super(errorLogger: errorLogger);

  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _firebaseAuth;
  final CredentialConverter _credentialConverter;

  @override
  Future<void> action() async {
    final account = await _googleSignIn.signIn();
    if (account != null) {
      final auth = await account.authentication;
      final credential = _credentialConverter.google(auth);
      await _firebaseAuth.signInWithCredential(credential);
    }
  }

  @override
  Future<Failure> onFailed(dynamic e, StackTrace stacktrace) {
    errorLogger.wtf('Unknown error', e, stacktrace);
    return Future.value(const UnknownFailure());
  }
}
