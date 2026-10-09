import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/storage/auth_tokens.dart';
import 'package:score/features/auth/storage/oidc_api.dart';

import '../../test_stores.dart';

/// What every request to the API is signed with, and what happens when there
/// is nothing to sign it with: the player is asked, once, and a no is taken
/// for an answer.

final _oidcConfig = OidcConfig(
  clientId: 'test',
  issuer: Uri.parse('http://nowhere'),
  redirectUri: Uri.parse('http://localhost/'),
  nativeRedirectUri: Uri.parse('app.wvl.score://callback'),
  desktopRedirectUri: Uri.parse('http://localhost:7005/'),
  authorizationEndpoint: Uri.parse('http://nowhere/authorize'),
  tokenEndpoint: Uri.parse('http://nowhere/token'),
  userInfoEndpoint: Uri.parse('http://nowhere/userinfo'),
  healthzEndpoint: Uri.parse('http://nowhere/healthz'),
  rolesKey: 'roles',
);

/// A provider handing out [token] — none while it is null — and counting how
/// often it was asked.
class _Provider({
  required Stores store,
}) extends OidcApi {
  this : super(config: _oidcConfig, store: store.auth);

  String? token;
  DateTime? goodUntil;
  String? subject = 'player';
  int asked = 0;

  @override
  Future<String?> getActiveAccessToken({bool signIn = true}) async {
    expect(signIn, isFalse, reason: "a sign-in is the prompt's to start");
    asked++;
    return token;
  }

  @override
  Future<DateTime?> accessTokenGoodUntil() async => goodUntil;

  @override
  Future<UserInfo?> keptUserInfo() async =>
      subject == null ? null : UserInfo(subject: subject);
}

/// A player who answers [answer], signing in with [signIn] when they say yes.
class _Prompt({
  required final SignInAnswer answer,
  final void Function()? signIn,
}) implements SignInPrompt {
  int asked = 0;

  /// Holds the answer back until it completes, when it is set.
  Completer<void>? thinking;

  @override
  Future<SignInAnswer> ask() async {
    asked++;
    await thinking?.future;
    if (answer == SignInAnswer.triedSigningIn) signIn?.call();
    return answer;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late Stores store;
  late _Provider oidc;

  setUp(() async {
    store = await Stores.inMemory();
    oidc = _Provider(store: store);
  });

  test('a token is held between requests rather than read for each', () async {
    oidc.token = 'a-token';
    final tokens = AuthTokens(
      oidc: oidc,
      prompt: _Prompt(answer: SignInAnswer.declined),
    );
    await _settle();

    expect(await tokens(), 'a-token');
    expect(await tokens(), 'a-token');
    expect(oidc.asked, 1);
  });

  test('a token that has run out is asked for again', () async {
    oidc
      ..token = 'old'
      ..goodUntil = DateTime.now().subtract(const Duration(seconds: 1));
    final tokens = AuthTokens(
      oidc: oidc,
      prompt: _Prompt(answer: SignInAnswer.declined),
    );
    await _settle();

    await tokens();
    oidc.token = 'new';

    expect(await tokens(), 'new');
  });

  test('a token is let go of once the tokens kept here change', () async {
    // A refresh in another tab, a sign-out, a token the API refused.
    oidc.token = 'old';
    final tokens = AuthTokens(
      oidc: oidc,
      prompt: _Prompt(answer: SignInAnswer.declined),
    );
    await _settle();
    await tokens();

    oidc.token = 'new';
    await store.auth.write('auth_token_response', '{}');
    await _settle();

    expect(await tokens(), 'new');
  });

  test(
    'with no token the player is asked once, however many are waiting',
    () async {
      final prompt = _Prompt(
        answer: SignInAnswer.triedSigningIn,
        signIn: () => oidc.token = 'signed-in',
      )..thinking = Completer<void>();
      final tokens = AuthTokens(oidc: oidc, prompt: prompt);
      await _settle();

      final waiting = [tokens(), tokens(), tokens()];
      await _settle();
      prompt.thinking!.complete();

      expect(await Future.wait(waiting), everyElement('signed-in'));
      expect(prompt.asked, 1);
    },
  );

  test('a no is taken for an answer until the next sign-in', () async {
    final prompt = _Prompt(answer: SignInAnswer.declined);
    final tokens = AuthTokens(oidc: oidc, prompt: prompt);
    await _settle();

    await expectLater(tokens(), throwsA(isA<NotSignedIn>()));
    await expectLater(tokens(), throwsA(isA<NotSignedIn>()));
    expect(prompt.asked, 1);

    // Signing in somewhere else — the profile page, another tab — and out
    // again: the next time there is no token is a new question.
    await store.auth.write('auth_token_response', '{}');
    await store.auth.write('auth_token_response', null);
    await _settle();

    await expectLater(tokens(), throwsA(isA<NotSignedIn>()));
    expect(prompt.asked, 2);
  });

  test('nobody there to ask is not a no', () async {
    final prompt = _Prompt(answer: SignInAnswer.couldNotAsk);
    final tokens = AuthTokens(oidc: oidc, prompt: prompt);
    await _settle();

    await expectLater(tokens(), throwsA(isA<NotSignedIn>()));
    await expectLater(tokens(), throwsA(isA<NotSignedIn>()));

    expect(prompt.asked, 2);
  });

  test('a sign-in that did not work is not a token', () async {
    final tokens = AuthTokens(
      oidc: oidc,
      prompt: _Prompt(answer: SignInAnswer.triedSigningIn),
    );
    await _settle();

    await expectLater(tokens(), throwsA(isA<NotSignedIn>()));
  });

  test('what was asked for as one user is not sent as another', () async {
    // Signed in as somebody else, the last user's sets would be sent as this
    // one's — and become theirs.
    final tokens = AuthTokens(
      oidc: oidc,
      prompt: _Prompt(
        answer: SignInAnswer.triedSigningIn,
        signIn: () => oidc
          ..token = 'someone-elses'
          ..subject = 'someone-else',
      ),
    );
    await _settle();

    await expectLater(tokens(), throwsA(isA<NotSignedIn>()));
    // The next request is asked for as the user who is signed in now.
    expect(await tokens(), 'someone-elses');
  });
}
