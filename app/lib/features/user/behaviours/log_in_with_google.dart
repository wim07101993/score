import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
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
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final auth = await account.authentication;
        final credential = _credentialConverter.google(auth);
        await _firebaseAuth.signInWithCredential(credential);
      }
    } on PlatformException catch (e) {
      if (e.code != 'popup_closed_by_user') {
        rethrow;
      }
    }
  }

  @override
  Future<Failure> onFailed(dynamic e, StackTrace stacktrace) {
    return Future.value(const UnknownFailure());
  }
}
