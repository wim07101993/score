import 'package:flutter_test/flutter_test.dart';
import 'package:score/config.dart';

void main() {
  Map<String, dynamic> oidc([Map<String, dynamic> more = const {}]) => {
    'discoveryEndpoint': 'https://auth.test/.well-known/openid-configuration',
    'healthzEndpoint': 'https://auth.test/healthz',
    'rolesKey': 'roles',
    'client': {
      'clientId': 'default-client',
      'redirectUri': 'https://score.test/redirect.html',
    },
    ...more,
  };

  test('reads the endpoints as addresses', () {
    final config = OidcConfig.fromJson(oidc());

    expect(
      config.discoveryEndpoint,
      Uri.parse('https://auth.test/.well-known/openid-configuration'),
    );
    expect(config.healthzEndpoint, Uri.parse('https://auth.test/healthz'));
  });

  test('always asks for openid, email and profile, once', () {
    final config = OidcConfig.fromJson(
      oidc({
        'scopes': ['offline_access', 'email'],
      }),
    );

    expect(config.scopes, ['openid', 'email', 'profile', 'offline_access']);
  });

  test('a desktop signs in as the desktop client when there is one', () {
    final config = OidcConfig.fromJson(
      oidc({
        'desktopClient': {'clientId': 'desktop-client'},
      }),
    );

    expect(config.clientConfig.clientId, 'desktop-client');
    expect(
      config.clientConfig.redirectUri,
      Uri.parse('http://localhost:7005'),
    );
  });

  test('and as the default client when there is not', () {
    final config = OidcConfig.fromJson(oidc());

    expect(config.clientConfig.clientId, 'default-client');
    expect(
      config.clientConfig.redirectUri,
      Uri.parse('https://score.test/redirect.html'),
    );
  });

  test('a phone redirects to the app when no address is given', () {
    final config = OidcConfig.fromJson(
      oidc({
        'mobileClient': {'clientId': 'mobile-client'},
      }),
    );

    expect(
      config.mobileClient?.redirectUri,
      Uri.parse('app.wvl.score://callback'),
    );
  });

  test('without a default client every platform needs its own', () {
    expect(
      () => OidcConfig.fromJson(
        oidc({
          'client': null,
          'webClient': {
            'clientId': 'web-client',
            'redirectUri': 'https://score.test/redirect.html',
          },
        }),
      ),
      throwsA(isA<OidcConfigInvalidException>()),
    );
  });

  test('without a roles key it is invalid', () {
    expect(
      () => OidcConfig.fromJson(oidc({'rolesKey': ''})),
      throwsA(isA<OidcConfigInvalidException>()),
    );
  });

  test('without a discovery endpoint it is invalid', () {
    expect(
      () => OidcConfig.fromJson(oidc({'discoveryEndpoint': null})),
      throwsA(isA<OidcConfigInvalidException>()),
    );
  });

  test('a client without an id is invalid', () {
    expect(
      () => OidcConfig.fromJson(
        oidc({
          'client': {
            'clientId': '',
            'redirectUri': 'https://score.test/redirect.html',
          },
        }),
      ),
      throwsA(isA<OidcClientConfigInvalidException>()),
    );
  });
}
