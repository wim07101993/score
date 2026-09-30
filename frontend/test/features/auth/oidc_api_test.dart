import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/authorizer.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/sembast/local_store.dart';

/// Signing in, with the provider played by a fake.
///
/// The protocol is `openid_client`'s now rather than this app's, which is
/// exactly why these exist: what the app is answerable for is no longer the
/// arithmetic of a code exchange but the *arrangement* — that the verifier it
/// sent is the one it proves the code with, that a token it kept is used again
/// rather than asked for twice, that a refresh token survives a provider which
/// does not reissue one, and that a provider nobody can reach still leaves the
/// app able to spend what it is holding.

/// Each test gets its own provider host.
///
/// `openid_client` keeps discovered metadata in a static map for the life of
/// the process, so two tests sharing an issuer would share whichever answer
/// arrived first.
int _hosts = 0;
String _nextHost() => 'provider${_hosts++}.test';

OidcConfig _config(String host) => OidcConfig(
      clientId: 'score-app',
      issuer: Uri.parse('https://$host'),
      redirectUri: Uri.parse('http://localhost:3000/'),
      nativeRedirectUri: Uri.parse('app.wvl.score://callback'),
      desktopRedirectUri: Uri.parse('http://localhost:7005/'),
      authorizationEndpoint: Uri.parse('https://$host/fallback/authorize'),
      tokenEndpoint: Uri.parse('https://$host/fallback/token'),
      userInfoEndpoint: Uri.parse('https://$host/fallback/userinfo'),
      healthzEndpoint: Uri.parse('https://$host/healthz'),
      rolesKey: 'urn:zitadel:iam:org:project:roles',
    );

Map<String, dynamic> _metadata(String host) => {
      'issuer': 'https://$host',
      'authorization_endpoint': 'https://$host/oauth/v2/authorize',
      'token_endpoint': 'https://$host/oauth/v2/token',
      'userinfo_endpoint': 'https://$host/oidc/v1/userinfo',
      'response_types_supported': ['code'],
      'scopes_supported': ['openid', 'email', 'profile', 'offline_access'],
      'grant_types_supported': ['authorization_code', 'refresh_token'],
    };

/// The user, played by something that answers instantly.
///
/// It records where it was sent and hands back a code with the state it was
/// given, which is what a provider that is behaving does.
class _Obliging implements Authorizer {
  _Obliging({this.state});

  /// The state to answer with. Null echoes back whatever it was sent, which is
  /// the honest case; setting it is how a mismatch is staged.
  final String? state;

  /// A code waiting from a previous life of the app, as the web has after a
  /// redirect.
  Callback? pending;

  Uri? sentTo;
  int cleared = 0;

  @override
  Uri get redirectUri => Uri.parse('http://localhost:3000/');

  @override
  Future<Callback?> authorize(Uri authorizationUrl) async {
    sentTo = authorizationUrl;
    return (
      code: 'the-code',
      state: state ?? authorizationUrl.queryParameters['state']!,
    );
  }

  @override
  Future<Callback?> pendingCallback() async => pending;

  @override
  Future<void> clearCallback() async {
    cleared++;
    pending = null;
  }

  /// Where the user is, as far as the next sign-in is concerned.
  Uri? here;

  /// Where the user was put back to, once signed in.
  Uri? returnedTo;

  @override
  Uri? whereTheUserIs() => here;

  @override
  Future<void> returnTo(Uri? where) async => returnedTo = where;
}

/// An authorizer that never answers.
///
/// This is the web, and it is not a failure: the page navigates away to the
/// provider and this app stops existing. Whatever it was waiting for arrives in
/// the *next* life of the app, through [Authorizer.pendingCallback].
class _GoesAway implements Authorizer {
  _GoesAway({this.here});

  Uri? sentTo;
  final Uri? here;

  @override
  Uri? whereTheUserIs() => here;
  @override
  Future<void> returnTo(Uri? where) async {}

  @override
  Uri get redirectUri => Uri.parse('http://localhost:3000/');
  @override
  Future<Callback?> authorize(Uri authorizationUrl) async {
    sentTo = authorizationUrl;
    return null;
  }

  @override
  Future<Callback?> pendingCallback() async => null;
  @override
  Future<void> clearCallback() async {}
}

/// A provider, as far as the app can tell.
class _Provider {
  _Provider(
    this.host, {
    this.discoverable = true,
    this.reissuesRefreshTokens = true,
    this.claims = const {},
    this.refused = const {},
  });

  /// Access tokens the provider no longer takes, however long they had left.
  final Set<String> refused;
  final List<String?> userInfoAskedWith = [];

  final String host;
  final bool discoverable;

  /// Whether a refresh answers with a new refresh token. Plenty do not, and a
  /// client that took the answer at its word would forget the one it had.
  final bool reissuesRefreshTokens;

  final Map<String, dynamic> claims;

  final List<Map<String, String>> tokenRequests = [];
  int discoveries = 0;
  int issued = 0;

  /// Every answer carries the request it is answering.
  ///
  /// `MockClient` does not fill that in, and `openid_client` reads it while
  /// logging every response — so a reply without it fails with a null check
  /// deep inside the package rather than anywhere near here.
  http.Client get client => MockClient((request) async {
        final path = request.url.path;

        if (path.endsWith('/.well-known/openid-configuration')) {
          discoveries++;
          if (!discoverable) {
            return http.Response('no', 500, request: request);
          }
          return http.Response(jsonEncode(_metadata(host)), 200,
              request: request,
              headers: {'content-type': 'application/json'});
        }

        if (path.endsWith('/token')) {
          final body = Uri.splitQueryString(request.body);
          tokenRequests.add(body);
          issued++;
          return http.Response(
            jsonEncode({
              'access_token': 'access-$issued',
              'token_type': 'Bearer',
              'expires_in': 3600,
              if (body['grant_type'] == 'authorization_code' ||
                  reissuesRefreshTokens)
                'refresh_token': 'refresh-$issued',
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path.endsWith('/userinfo')) {
          final bearer = request.headers['Authorization']?.substring(7);
          userInfoAskedWith.add(bearer);
          if (refused.contains(bearer)) {
            return http.Response('revoked', 401, request: request);
          }
          return http.Response(jsonEncode(claims), 200,
              request: request,
              headers: {'content-type': 'application/json'});
        }

        if (path.endsWith('/healthz')) {
          return http.Response('ok', 200, request: request);
        }

        return http.Response('not found: ${request.url}', 404,
            request: request);
      });
}

Future<(OidcApi, LocalStore)> _api(
  _Provider provider, {
  Authorizer? authorizer,
  LocalStore? store,
}) async {
  final held = store ?? await LocalStore.inMemory();
  return (
    OidcApi(
      _config(provider.host),
      held,
      client: provider.client,
      authorizer: authorizer ?? _Obliging(),
    ),
    held,
  );
}

void main() {
  group('being sent to the provider', () {
    test('is asked for with a challenge, and the discovered endpoint', () async {
      final provider = _Provider(_nextHost());
      final authorizer = _Obliging();
      final (api, _) = await _api(provider, authorizer: authorizer);

      await api.getActiveAccessToken();

      final sent = authorizer.sentTo!;
      // The endpoint the provider named, not the one the config guessed.
      expect(sent.path, '/oauth/v2/authorize');
      expect(sent.queryParameters['code_challenge_method'], 'S256');
      expect(sent.queryParameters['code_challenge'], isNotEmpty);
      expect(sent.queryParameters['client_id'], 'score-app');
      expect(sent.queryParameters['response_type'], 'code');
      expect(sent.queryParameters['redirect_uri'], 'http://localhost:3000/');

      // The verifier itself never leaves the device.
      expect(sent.queryParameters.containsKey('code_verifier'), isFalse);

      // Including the one that decides whether a refresh token is ever issued.
      final scopes = sent.queryParameters['scope']!.split(' ');
      expect(scopes, containsAll(['openid', 'offline_access']));
    });

    test('proves the code with the verifier it sent', () async {
      final provider = _Provider(_nextHost());
      final (api, _) = await _api(provider);

      final token = await api.getActiveAccessToken();

      expect(token, 'access-1');
      final exchange = provider.tokenRequests.single;
      expect(exchange['grant_type'], 'authorization_code');
      expect(exchange['code'], 'the-code');
      expect(exchange['code_verifier'], isNotEmpty);
      expect(exchange['redirect_uri'], 'http://localhost:3000/');
    });

    test('refuses a code that came back with a state it never sent', () async {
      final provider = _Provider(_nextHost());
      final (api, _) = await _api(
        provider,
        authorizer: _Obliging(state: 'not-the-state-that-went-out'),
      );

      // A code addressed to a sign-in this device did not start is a code it
      // must not spend — and no token request should ever be made for it.
      expect(await api.getActiveAccessToken(), isNull);
      expect(provider.tokenRequests, isEmpty);
    });

    test('picks up a code the app was started with', () async {
      final provider = _Provider(_nextHost());
      final store = await LocalStore.inMemory();

      // The web: the flow starts and the page navigates away, so this app gets
      // no answer at all — it stops running.
      final leaving = _GoesAway();
      final (first, _) = await _api(provider, authorizer: leaving, store: store);
      expect(await first.getActiveAccessToken(), isNull);
      final state = leaving.sentTo!.queryParameters['state']!;

      // ...and starts again with the answer in its own address.
      final restarted = _Obliging()
        ..pending = (code: 'the-code', state: state);
      final (second, _) = await _api(
        _Provider(provider.host),
        authorizer: restarted,
        store: store,
      );

      expect(await second.getActiveAccessToken(), isNotNull);
      expect(restarted.cleared, 1,
          reason: 'a code left in the address would be spent twice on reload');
      expect(restarted.sentTo, isNull,
          reason: 'it had an answer already; it should not have asked again');
    });

    test("is not done for work running behind the user's back", () async {
      // A sync or a queued write finding no token: on the web a sign-in is the
      // page leaving, and a token the API keeps refusing would be signed in
      // for over and over with nobody asking.
      final provider = _Provider(_nextHost());
      final authorizer = _Obliging();
      final (api, _) = await _api(provider, authorizer: authorizer);

      expect(await api.getActiveAccessToken(signIn: false), isNull);
      expect(authorizer.sentTo, isNull);
      expect(await api.holdsAToken(), isFalse);
    });

    test("behind the user's back still spends a refresh token", () async {
      final provider = _Provider(_nextHost());
      final store = await LocalStore.inMemory();
      await store.writeSetting(
        'auth_token_response',
        jsonEncode({'token_type': 'Bearer', 'refresh_token': 'the-refresh'}),
      );
      final authorizer = _Obliging();
      final (api, _) =
          await _api(provider, authorizer: authorizer, store: store);

      expect(await api.getActiveAccessToken(signIn: false), 'access-1');
      expect(authorizer.sentTo, isNull);
    });

    test('two tabs sent to sign in at once each keep their own sign-in',
        () async {
      // Every tab of the web app shares the one store. The sign-in the second
      // tab started must not be written over the first's, or the first to come
      // back is refused for a state that is not its own.
      final provider = _Provider(_nextHost());
      final store = await LocalStore.inMemory();
      final firstTab = _GoesAway();
      final secondTab = _GoesAway();
      final (first, _) =
          await _api(provider, authorizer: firstTab, store: store);
      final (second, _) =
          await _api(_Provider(provider.host), authorizer: secondTab, store: store);
      await first.getActiveAccessToken();
      await second.getActiveAccessToken();

      final back = _Obliging()
        ..pending = (
          code: 'the-code',
          state: firstTab.sentTo!.queryParameters['state']!,
        );
      final (firstAgain, _) =
          await _api(_Provider(provider.host), authorizer: back, store: store);

      expect(await firstAgain.getActiveAccessToken(), isNotNull);
      expect(firstAgain.signInFailure, isNull);
    });

    test('forgetting the user forgets every sign-in that is out', () async {
      final provider = _Provider(_nextHost());
      final store = await LocalStore.inMemory();
      final leaving = _GoesAway();
      final (api, _) = await _api(provider, authorizer: leaving, store: store);
      await api.getActiveAccessToken();

      await api.forgetUser();

      final back = _Obliging()
        ..pending = (
          code: 'the-code',
          state: leaving.sentTo!.queryParameters['state']!,
        );
      final (again, _) =
          await _api(_Provider(provider.host), authorizer: back, store: store);
      expect(await again.getActiveAccessToken(), isNot('access-1'),
          reason: 'a sign-in started before signing out was finished after it');
    });

    test('puts the user back where the sign-in was started from', () async {
      final provider = _Provider(_nextHost());
      final store = await LocalStore.inMemory();
      final link = Uri.parse('http://localhost:3000/scores/abc?set=def');

      // A link to a score, opened in a tab with no token in it.
      final leaving = _GoesAway(here: link);
      final (first, _) = await _api(provider, authorizer: leaving, store: store);
      await first.getActiveAccessToken();
      final state = leaving.sentTo!.queryParameters['state']!;

      // The provider sends it back to the front page.
      final restarted = _Obliging()
        ..pending = (code: 'the-code', state: state)
        ..here = Uri.parse('http://localhost:3000/');
      final (second, _) = await _api(
        _Provider(provider.host),
        authorizer: restarted,
        store: store,
      );

      expect(await second.getActiveAccessToken(), isNotNull);
      expect(restarted.returnedTo, link);
    });
  });

  group('a token it is already holding', () {
    test('is used again rather than asked for twice', () async {
      final provider = _Provider(_nextHost());
      final store = await LocalStore.inMemory();

      final (first, _) = await _api(provider, store: store);
      expect(await first.getActiveAccessToken(), 'access-1');

      final authorizer = _Obliging();
      final (second, _) = await _api(
        _Provider(provider.host),
        authorizer: authorizer,
        store: store,
      );

      expect(await second.getActiveAccessToken(), 'access-1');
      expect(authorizer.sentTo, isNull,
          reason: 'the player was sent away holding a token that was fine');
    });

    test('is refreshed once it has run out', () async {
      final provider = _Provider(_nextHost());
      final store = await LocalStore.inMemory();

      await store.writeSetting(
        'auth_token_response',
        jsonEncode({
          'access_token': 'stale',
          'token_type': 'Bearer',
          'refresh_token': 'the-refresh-token',
          'expires_at':
              DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/
                  1000,
        }),
      );

      final authorizer = _Obliging();
      final (api, _) = await _api(provider, authorizer: authorizer, store: store);

      expect(await api.getActiveAccessToken(), 'access-1');
      expect(provider.tokenRequests.single['grant_type'], 'refresh_token');
      expect(provider.tokenRequests.single['refresh_token'],
          'the-refresh-token');
      expect(authorizer.sentTo, isNull,
          reason: 'a refresh that worked should not disturb the player');
    });

    test('is refreshed while it still has a moment left on it', () async {
      final provider = _Provider(_nextHost());
      final store = await LocalStore.inMemory();

      // Ten seconds left: still valid, and not enough to be worth spending on a
      // request that has to travel.
      await store.writeSetting(
        'auth_token_response',
        jsonEncode({
          'access_token': 'nearly-gone',
          'token_type': 'Bearer',
          'refresh_token': 'the-refresh-token',
          'expires_at':
              DateTime.now().add(const Duration(seconds: 10)).millisecondsSinceEpoch ~/
                  1000,
        }),
      );

      final (api, _) = await _api(provider, store: store);

      expect(await api.getActiveAccessToken(), 'access-1');
      expect(provider.tokenRequests.single['grant_type'], 'refresh_token');
    });

    test('is not thrown away when another tab spent its refresh token first',
        () async {
      // Two tabs opened again the next morning both find the token run out and
      // both refresh with the same refresh token. A provider that rotates them
      // takes it once; the tab that lost goes on with what the other wrote down
      // rather than throwing it away and sending both to sign in.
      final host = _nextHost();
      final store = await LocalStore.inMemory();
      final expired =
          DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/
              1000;
      await store.writeSetting(
        'auth_token_response',
        jsonEncode({
          'access_token': 'stale',
          'token_type': 'Bearer',
          'refresh_token': 'spent-by-the-other-tab',
          'expires_at': expired,
        }),
      );

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/.well-known/openid-configuration')) {
          return http.Response(jsonEncode(_metadata(host)), 200,
              request: request,
              headers: {'content-type': 'application/json'});
        }
        // The other tab's refresh lands first, and is written down...
        await store.writeSetting(
          'auth_token_response',
          jsonEncode({
            'access_token': 'the-other-tabs',
            'token_type': 'Bearer',
            'refresh_token': 'the-other-tabs-refresh-token',
            'expires_at': DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          }),
        );
        // ...and this one is refused for spending the same token again.
        return http.Response(jsonEncode({'error': 'invalid_grant'}), 400,
            request: request,
            headers: {'content-type': 'application/json'});
      });
      final authorizer = _Obliging();
      final api = OidcApi(_config(host), store,
          client: client, authorizer: authorizer);

      expect(await api.getActiveAccessToken(), 'the-other-tabs');
      expect(authorizer.sentTo, isNull,
          reason: 'a tab that lost a race was sent to sign in');
      final kept =
          jsonDecode((await store.readSetting('auth_token_response'))!) as Map;
      expect(kept['refresh_token'], 'the-other-tabs-refresh-token');
    });

    test("waits a moment for the other tab's token to reach this one",
        () async {
      // On the web the other tab's write reaches this tab's store a moment
      // after it was made — often after the refusal of the race it won.
      final host = _nextHost();
      final store = await LocalStore.inMemory();
      final expired =
          DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/
              1000;
      await store.writeSetting(
        'auth_token_response',
        jsonEncode({
          'access_token': 'stale',
          'token_type': 'Bearer',
          'refresh_token': 'spent-by-the-other-tab',
          'expires_at': expired,
        }),
      );

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/.well-known/openid-configuration')) {
          return http.Response(jsonEncode(_metadata(host)), 200,
              request: request,
              headers: {'content-type': 'application/json'});
        }
        // Refused at once; the other tab's token arrives a little later.
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          return store.writeSetting(
            'auth_token_response',
            jsonEncode({
              'access_token': 'the-other-tabs',
              'token_type': 'Bearer',
              'refresh_token': 'the-other-tabs-refresh-token',
              'expires_at': DateTime.now()
                      .add(const Duration(hours: 1))
                      .millisecondsSinceEpoch ~/
                  1000,
            }),
          );
        });
        return http.Response(jsonEncode({'error': 'invalid_grant'}), 400,
            request: request,
            headers: {'content-type': 'application/json'});
      });
      final authorizer = _Obliging();
      final api = OidcApi(_config(host), store,
          client: client,
          authorizer: authorizer,
          otherTabsGrace: const Duration(seconds: 2));

      expect(await api.getActiveAccessToken(), 'the-other-tabs');
      expect(authorizer.sentTo, isNull,
          reason: 'a tab that lost a race was sent to sign in');
      final kept =
          jsonDecode((await store.readSetting('auth_token_response'))!) as Map;
      expect(kept['refresh_token'], 'the-other-tabs-refresh-token',
          reason: 'the token the other tab won was thrown away');
    });

    test('keeps its refresh token when the provider sends no new one', () async {
      final provider =
          _Provider(_nextHost(), reissuesRefreshTokens: false);
      final store = await LocalStore.inMemory();

      final (first, _) = await _api(provider, store: store);
      await first.getActiveAccessToken();

      // Run it out, and refresh again. The second refresh has to use the token
      // from the first exchange, because the provider never sent another.
      final kept =
          jsonDecode((await store.readSetting('auth_token_response'))!) as Map;
      kept['expires_at'] =
          DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/
              1000;
      await store.writeSetting('auth_token_response', jsonEncode(kept));

      final (second, _) = await _api(
        _Provider(provider.host, reissuesRefreshTokens: false),
        store: store,
      );
      expect(await second.getActiveAccessToken(), isNotNull);

      final after =
          jsonDecode((await store.readSetting('auth_token_response'))!) as Map;
      expect(after['refresh_token'], 'refresh-1',
          reason: 'the only refresh token this device had was thrown away');
    });
  });

  group('a provider that cannot be described', () {
    test('falls back to the endpoints the config was built with', () async {
      final provider = _Provider(_nextHost(), discoverable: false);
      final authorizer = _Obliging();
      final (api, _) = await _api(provider, authorizer: authorizer);

      expect(await api.getActiveAccessToken(), 'access-1');
      expect(provider.discoveries, greaterThan(0));

      // The written-down endpoint, since there was nobody to ask.
      expect(authorizer.sentTo!.path, '/fallback/authorize');

      // And the scopes still went out. A metadata document with no
      // `scopes_supported` would have quietly dropped every one of them,
      // including `openid`.
      final scopes = authorizer.sentTo!.queryParameters['scope']!.split(' ');
      expect(scopes, containsAll(['openid', 'offline_access']));
    });
  });

  group('the user', () {
    test('is read out of the provider, roles and all', () async {
      final provider = _Provider(
        _nextHost(),
        claims: {
          'sub': 'user-1',
          'name': 'A Player',
          'email': 'player@example.com',
          'urn:zitadel:iam:org:project:roles': {
            'score_viewer': {'org': 'x'},
          },
        },
      );
      final (api, store) = await _api(provider);

      final user = (await api.getUserInfo())!;
      expect(user.name, 'A Player');
      expect(user.subject, 'user-1');
      expect(user.isScoreViewer, isTrue);
      expect(user.isScoreEditor, isFalse);

      // Kept, so that a rehearsal hall with no signal still knows who this is.
      final remembered = await api.keptUserInfo();
      expect(remembered!.name, 'A Player');
      expect(remembered.isScoreViewer, isTrue);
      expect(store, isNotNull);
    });

    test('is asked about again with a refreshed token when the provider'
        ' refuses the one held', () async {
      // Revoked, or signed out somewhere else: this device still thinks it has
      // an hour left on it.
      final provider = _Provider(
        _nextHost(),
        claims: const {'sub': 'user-1', 'name': 'A Player'},
        refused: const {'revoked'},
      );
      final store = await LocalStore.inMemory();
      await store.writeSetting(
        'auth_token_response',
        jsonEncode({
          'access_token': 'revoked',
          'token_type': 'Bearer',
          'refresh_token': 'the-refresh-token',
          'expires_at':
              DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
                  1000,
        }),
      );
      final authorizer = _Obliging();
      final (api, _) = await _api(provider, authorizer: authorizer, store: store);

      final user = await api.getUserInfo();

      expect(user?.name, 'A Player');
      expect(provider.userInfoAskedWith, ['revoked', 'access-1']);
      expect(provider.tokenRequests.single['grant_type'], 'refresh_token');
      expect(authorizer.sentTo, isNull,
          reason: 'a refresh that worked should not disturb the player');
      expect(await api.getActiveAccessToken(), 'access-1',
          reason: 'the refused token was kept');
    });

    test('is signed in for again when a refused token cannot be refreshed',
        () async {
      final provider = _Provider(
        _nextHost(),
        claims: const {'sub': 'user-1'},
        refused: const {'revoked'},
      );
      final store = await LocalStore.inMemory();
      await store.writeSetting(
        'auth_token_response',
        jsonEncode({
          'access_token': 'revoked',
          'token_type': 'Bearer',
          'expires_at':
              DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
                  1000,
        }),
      );
      final authorizer = _Obliging();
      final (api, _) = await _api(provider, authorizer: authorizer, store: store);

      await api.getUserInfo();

      expect(authorizer.sentTo, isNotNull);
      expect(provider.userInfoAskedWith.last, 'access-1');
    });

    test('is forgotten on the way out', () async {
      final provider = _Provider(_nextHost(), claims: const {'sub': 'user-1'});
      final (api, store) = await _api(provider);

      await api.getUserInfo();
      await api.forgetUser();

      expect(await store.readSetting('auth_token_response'), isNull);
      expect(await store.readSetting('app_user_info'), isNull);
      expect(await api.keptUserInfo(), isNull);
    });

    test('is nobody when the provider will not talk and nothing is kept', () async {
      final provider = _Provider(_nextHost(), discoverable: false);
      final (api, _) = await _api(provider, authorizer: _GoesAway());

      expect(await api.getUserInfo(), isNull);
      expect(await api.keptUserInfo(), isNull);
    });
  });
}
