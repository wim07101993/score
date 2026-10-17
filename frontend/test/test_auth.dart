import 'package:score/config.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';

import 'test_oidc.dart';

Future<AuthNotifier> signedIn() async {
  final notifier = AuthNotifier(
    manager: TestOidcUserManager(user: await testOidcUser()),
    config: OidcConfig.fromJson({
      'discoveryEndpoint':
          'https://auth.invalid/.well-known/openid-configuration',
      'healthzEndpoint': 'https://auth.invalid/healthz',
      'rolesKey': 'roles',
      'client': {
        'clientId': 'test',
        'redirectUri': 'http://localhost:3000/redirect.html',
      },
    }),
  );
  await notifier.ready;
  return notifier;
}
