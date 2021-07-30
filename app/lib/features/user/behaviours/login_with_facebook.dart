import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:score/features/user/behaviours/credential_converter.dart';

class LogInWithFacebook extends BehaviourWithoutInput<void> {
  LogInWithFacebook({
    required Logger errorLogger,
    required FacebookAuth facebookAuth,
    required FirebaseAuth firebaseAuth,
    required CredentialConverter credentialConverter,
  })  : _facebookAuth = facebookAuth,
        _firebaseAuth = firebaseAuth,
        _credentialConverter = credentialConverter,
        super(errorLogger: errorLogger);

  final FacebookAuth _facebookAuth;
  final FirebaseAuth _firebaseAuth;
  final CredentialConverter _credentialConverter;

  @override
  Future<void> action() async {
    final result = await _facebookAuth.login();
    if (result.status == LoginStatus.success) {
      final credential = _credentialConverter.facebook(
        result.accessToken!.token,
      );
      await _firebaseAuth.signInWithCredential(credential);
    }
  }

  @override
  Future<Failure> onFailed(dynamic e, StackTrace stacktrace) {
    errorLogger.wtf('Unknown error', e, stacktrace);
    return Future.value(const UnknownFailure());
  }
}
