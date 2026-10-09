import 'dart:async';

import 'package:score/features/auth/storage/oidc_api.dart';

/// What [AuthTokens] does when there is no token: asks the player whether to
/// sign in. Said here and done by a page, which is where a player can be asked
/// anything.
abstract interface class SignInPrompt {
  Future<SignInAnswer> ask();
}

enum SignInAnswer {
  /// The player said yes, and signing in was tried. Whether it worked is told
  /// by the token there is afterwards.
  triedSigningIn,

  /// The player said no.
  declined,

  /// There was nobody to ask: nothing is on screen yet.
  couldNotAsk,
}

/// There is no token to send a request with, and the player was not signed in
/// for one.
class const NotSignedIn({
  final String message = 'you are not signed in',
}) implements Exception {
  @override
  String toString() => message;
}

/// The token every request to the API is sent with.
///
/// Held here between requests, until it runs out or the tokens this device
/// keeps change — a refresh in another tab, a sign-out, a token the API
/// refused — so that a sync of fifty writes reads it once rather than fifty
/// times.
///
/// When there is none, the player is asked whether to sign in rather than sent
/// to the provider without a word: on the web a sign-in is the page leaving,
/// and on a desktop a browser opening out of nowhere. Everything that wants a
/// token while the question is out waits for the one answer. A no is
/// remembered until the next sign-in, so that a sync going round does not ask
/// again every time it does.
class AuthTokens({
  required final OidcApi oidc,
  required final SignInPrompt prompt,
}) {
  this {
    _watching = oidc.watchTokens().listen((_) {
      _held = null;
      _declined = false;
    });
  }

  late final StreamSubscription<void> _watching;

  ({String token, DateTime? until})? _held;
  bool _declined = false;
  Future<String>? _asking;

  /// A token that is good right now. Throws [NotSignedIn] when there is none
  /// and the player did not sign in for one.
  Future<String> call() async {
    final held = _held;
    if (held != null &&
        (held.until == null || held.until!.isAfter(DateTime.now()))) {
      return held.token;
    }
    _held = null;

    final token = await oidc.getActiveAccessToken(signIn: false);
    if (token != null) {
      return _hold(token);
    }
    if (_declined) {
      throw const NotSignedIn();
    }
    return _asking ??= _ask().whenComplete(() => _asking = null);
  }

  Future<String> _ask() async {
    final before = (await oidc.keptUserInfo())?.subject;
    switch (await prompt.ask()) {
      case SignInAnswer.couldNotAsk:
        throw const NotSignedIn();
      case SignInAnswer.declined:
        _declined = true;
        throw const NotSignedIn();
      case SignInAnswer.triedSigningIn:
        break;
    }
    final token = await oidc.getActiveAccessToken(signIn: false);
    if (token == null) {
      throw const NotSignedIn();
    }
    // What was waiting for the token was asked for as the user who was signed
    // in then. Sent as somebody else, a set of theirs would become this one's.
    final after = (await oidc.keptUserInfo())?.subject;
    if (before != null && after != before) {
      throw const NotSignedIn(
        message:
            'signed in as somebody else; what was asked for as the last'
            ' user is not sent as this one',
      );
    }
    return _hold(token);
  }

  Future<String> _hold(String token) async {
    _held = (token: token, until: await oidc.accessTokenGoodUntil());
    return token;
  }

  Future<void> dispose() => _watching.cancel();
}
