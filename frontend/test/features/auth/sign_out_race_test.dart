import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/authorizer.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/sembast/local_store.dart';

const _rolesKey = 'urn:zitadel:iam:org:project:roles';

final _claimsA = <String, dynamic>{
  'sub': 'user-A',
  'name': 'Alice',
  'email': 'alice@example.test',
  _rolesKey: {
    'score_viewer': {'org': 'x'},
  },
};

/// A provider whose token endpoint (and optionally userinfo) answers only when
/// told to.
class _SlowProvider({
  required final String host,
  final bool gateUserInfo = false,
}) {
  final tokenRequested = Completer<void>();
  final releaseToken = Completer<void>();
  final userInfoRequested = Completer<void>();
  final releaseUserInfo = Completer<void>();
  final List<Map<String, String>> tokenRequests = [];
  final List<String?> userInfoAskedWith = [];
  int issued = 0;

  http.Client get client => MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/.well-known/openid-configuration')) {
          return http.Response(
            jsonEncode({
              'issuer': 'https://$host',
              'authorization_endpoint': 'https://$host/oauth/v2/authorize',
              'token_endpoint': 'https://$host/oauth/v2/token',
              'userinfo_endpoint': 'https://$host/oidc/v1/userinfo',
              'response_types_supported': ['code'],
              'scopes_supported': ['openid', 'email', 'profile', 'offline_access'],
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.endsWith('/healthz')) {
          return http.Response('ok', 200, request: request);
        }
        if (path.endsWith('/token')) {
          tokenRequests.add(Uri.splitQueryString(request.body));
          if (!tokenRequested.isCompleted) tokenRequested.complete();
          await releaseToken.future;
          issued++;
          return http.Response(
            jsonEncode({
              'access_token': 'access-new-$issued',
              'token_type': 'Bearer',
              'expires_in': 3600,
              'refresh_token': 'refresh-new-$issued',
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        if (path.endsWith('/userinfo')) {
          userInfoAskedWith.add(request.headers['Authorization']?.substring(7));
          if (gateUserInfo) {
            if (!userInfoRequested.isCompleted) userInfoRequested.complete();
            await releaseUserInfo.future;
          }
          return http.Response(jsonEncode(_claimsA), 200,
              request: request, headers: {'content-type': 'application/json'});
        }
        return http.Response('not found', 404, request: request);
      });
}

/// An authorizer that records whether the user was ever sent to sign in.
class _Recording implements Authorizer {
  Uri? sentTo;
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
  @override
  Uri? whereTheUserIs() => null;
  @override
  Future<void> returnTo(Uri? where) async {}
}

OidcConfig _config(String host) => OidcConfig(
      clientId: 'score-app',
      issuer: Uri.parse('https://$host'),
      redirectUri: Uri.parse('http://localhost:3000/'),
      nativeRedirectUri: Uri.parse('app.wvl.score://callback'),
      desktopRedirectUri: Uri.parse('http://localhost:7005/'),
      authorizationEndpoint: Uri.parse('https://$host/fallback/authorize'),
      tokenEndpoint: Uri.parse('https://$host/fallback/token'),
      userInfoEndpoint: Uri.parse('https://$host/oidc/v1/userinfo'),
      healthzEndpoint: Uri.parse('https://$host/healthz'),
      rolesKey: _rolesKey,
    );

String _expiredToken() => jsonEncode({
      'access_token': 'stale',
      'token_type': 'Bearer',
      'refresh_token': 'the-refresh-token',
      'expires_at': DateTime.now()
              .subtract(const Duration(minutes: 1))
              .millisecondsSinceEpoch ~/
          1000,
    });

String _validToken() => jsonEncode({
      'access_token': 'still-good',
      'token_type': 'Bearer',
      'refresh_token': 'the-refresh-token',
      'expires_at': DateTime.now()
              .add(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000,
    });

void main() {
  test('a refresh that answers after signing out is not kept', () async {
    final store = await LocalStore.inMemory();
    await store.writeSetting('auth_token_response', _expiredToken());
    await store.writeSetting('app_user_info',
        jsonEncode(UserInfo.fromClaims(claims: _claimsA, rolesKey: _rolesKey).toJson()));

    final provider = _SlowProvider(host: 'provider-a.test');
    final api = OidcApi(config: _config(provider.host), store: store,
        client: provider.client, authorizer: _Recording());

    // A sync asking for a token behind the user's back.
    final syncToken = api.getActiveAccessToken(signIn: false);
    await provider.tokenRequested.future.timeout(const Duration(seconds: 10));

    await api.signOut();
    provider.releaseToken.complete();

    expect(await syncToken, isNull);
    expect(await api.holdsAToken(), isFalse);

    // And the next start asks who it is, rather than going on as them.
    final authorizer = _Recording();
    final next = OidcApi(config: _config(provider.host), store: store,
        client: provider.client, authorizer: authorizer);
    expect(await next.getUserInfo(), isNull);
    expect(authorizer.sentTo, isNotNull);
  });

  test('who the provider says it is, said after signing out, is not kept',
      () async {
    final store = await LocalStore.inMemory();
    await store.writeSetting('auth_token_response', _validToken());
    await store.writeSetting('app_user_info',
        jsonEncode(UserInfo.fromClaims(claims: _claimsA, rolesKey: _rolesKey).toJson()));

    final provider = _SlowProvider(host: 'provider-b.test', gateUserInfo: true);
    final api = OidcApi(config: _config(provider.host), store: store,
        client: provider.client, authorizer: _Recording());

    final asked = api.getUserInfo();
    await provider.userInfoRequested.future
        .timeout(const Duration(seconds: 10));
    await api.signOut();
    provider.releaseUserInfo.complete();

    expect(await asked, isNull);
    expect(await api.keptUserInfo(), isNull);
    expect(await api.holdsAToken(), isFalse);
  });
}
