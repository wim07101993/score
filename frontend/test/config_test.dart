import 'package:flutter_test/flutter_test.dart';
import 'package:score/config.dart';

void main() {
  Map<String, dynamic> oidc([Map<String, dynamic> more = const {}]) => {
        'clientId': 'web-client',
        'redirectUri': 'https://score.test/',
        'authorizationEndpoint': 'https://auth.test/oauth/v2/authorize',
        'tokenEndpoint': 'https://auth.test/oauth/v2/token',
        'userInfoEndpoint': 'https://auth.test/oidc/v1/userinfo',
        'healthzEndpoint': 'https://auth.test/healthz',
        'rolesKey': 'roles',
        ...more,
      };

  test('a phone or a desktop signs in as the native client when there is one',
      () {
    final config = OidcConfig.fromJson(oidc({'nativeClientId': 'native'}));

    expect(config.clientId, 'web-client');
    expect(config.nativeClientId, 'native');
    // Tests run as a device, not in a browser.
    expect(config.clientIdHere, 'native');
  });

  test('and as the web client when there is not', () {
    final config = OidcConfig.fromJson(oidc());

    expect(config.nativeClientId, 'web-client');
    expect(config.clientIdHere, 'web-client');
  });
}
