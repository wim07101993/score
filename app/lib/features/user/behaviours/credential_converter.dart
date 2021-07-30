import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CredentialConverter {
  const CredentialConverter();

  OAuthCredential google(GoogleSignInAuthentication auth) {
    return GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
  }

  OAuthCredential facebook(String token) {
    return FacebookAuthProvider.credential(token);
  }
}
