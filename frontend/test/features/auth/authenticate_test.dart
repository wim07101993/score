import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:oidc/oidc.dart';
import 'package:score/behaviours/exception_or.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/authentication_exception.dart';
import 'package:score/features/auth/behaviours/authenticate.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/auth/user_info.dart';

import '../../test_oidc.dart';

final _config = OidcConfig(
  discoveryEndpoint: Uri.parse(
    'https://provider.test/.well-known/openid-configuration',
  ),
  healthzEndpoint: Uri.parse('https://provider.test/healthz'),
  rolesKey: 'roles',
  client: OidcClientConfig(
    clientId: 'score-app',
    redirectUri: Uri.parse('http://localhost:3000/redirect.html'),
  ),
  webClient: null,
  mobileClient: null,
  desktopClient: null,
  scopes: const ['offline_access'],
);

Future<UserInfo> _authenticate(
  TestOidcUserManager manager, {
  bool mayAskTheUser = true,
  bool forceRefresh = false,
}) async =>
    (await Authenticate(
          manager: manager,
          config: _config,
          logger: Logger('test'),
        )(
          AuthenticateParams(
            mayAskTheUser: mayAskTheUser,
            forceRefresh: forceRefresh,
          ),
        ))
        .orThrow();

void main() {
  group('a user who is signed in', () {
    test('is handed the token they hold, and who they are', () async {
      final manager = TestOidcUserManager(
        user: await testOidcUser(
          claims: {
            'sub': 'player',
            'name': 'A Player',
            'roles': {'score_viewer': {}},
          },
          accessToken: 'held',
        ),
      );

      final user = await _authenticate(manager);

      expect(user.accessToken, 'held');
      expect(user.id, 'player');
      expect(user.name, 'A Player');
      expect(manager.signIns, 0);
    });

    test('can have their token refreshed on demand', () async {
      final manager = TestOidcUserManager(
        user: await testOidcUser(accessToken: 'refreshed'),
      );

      final user = await _authenticate(
        manager,
        mayAskTheUser: false,
        forceRefresh: true,
      );

      expect(user.accessToken, 'refreshed');
      expect(manager.forcedRefreshes, 1);
      expect(manager.signIns, 0);
    });

    test('is not refreshed unless asked', () async {
      final manager = TestOidcUserManager(user: await testOidcUser());

      await _authenticate(manager);

      expect(manager.forcedRefreshes, 0);
    });

    test('without a refresh token has to sign in again to refresh', () async {
      final manager = TestOidcUserManager(user: await testOidcUser())
        ..accessTokenFailure = const OidcInteractionRequiredException(
          message: 'no refresh token',
        );

      await expectLater(
        _authenticate(manager, mayAskTheUser: false, forceRefresh: true),
        throwsA(isA<SignInRequired>()),
      );
    });

    test('whose provider cannot be reached is told so', () async {
      final manager = TestOidcUserManager(user: await testOidcUser())
        ..accessTokenFailure = const OidcException(
          'timed out',
          kind: OidcTokenRefreshFailureKind.transient,
        );

      await expectLater(
        _authenticate(manager),
        throwsA(isA<ProviderUnreachable>()),
      );
    });
  });

  group('a user who is not signed in', () {
    test('is signed in', () async {
      final manager = TestOidcUserManager()
        ..signsInAs = await testOidcUser(accessToken: 'new');

      final user = await _authenticate(manager);

      expect(user.accessToken, 'new');
      expect(manager.signIns, 1);
    });

    test('is not signed in when they may not be asked', () async {
      final manager = TestOidcUserManager()..signsInAs = await testOidcUser();

      await expectLater(
        _authenticate(manager, mayAskTheUser: false),
        throwsA(isA<SignInRequired>()),
      );
      expect(manager.signIns, 0);
    });

    test('whose refresh token was refused is signed in again', () async {
      final manager = TestOidcUserManager(user: await testOidcUser())
        ..accessTokenFailure = const OidcInteractionRequiredException(
          message: 'refused',
        )
        ..signsInAs = await testOidcUser(accessToken: 'again');

      expect((await _authenticate(manager)).accessToken, 'again');
    });
  });

  group('a sign-in', () {
    test('the user walked away from is cancelled', () async {
      final manager = TestOidcUserManager();

      await expectLater(
        _authenticate(manager),
        throwsA(isA<SignInCancelled>()),
      );
    });

    test('whose window was closed is cancelled', () async {
      final manager = TestOidcUserManager()
        ..signInFailure = const OidcException(
          'closed',
          extra: {'reason': 'window_closed'},
        );

      await expectLater(
        _authenticate(manager),
        throwsA(isA<SignInCancelled>()),
      );
    });

    test('the user said no to is cancelled', () async {
      final manager = TestOidcUserManager()
        ..signInFailure = OidcException.serverError(
          errorResponse: OidcErrorResponse.fromJson({'error': 'access_denied'}),
        );

      await expectLater(
        _authenticate(manager),
        throwsA(isA<SignInCancelled>()),
      );
    });

    test('the provider refused failed', () async {
      final manager = TestOidcUserManager()
        ..signInFailure = OidcException.serverError(
          errorResponse: OidcErrorResponse.fromJson({
            'error': 'invalid_client',
          }),
        );

      await expectLater(_authenticate(manager), throwsA(isA<SignInFailed>()));
    });

    test('without a network is the provider not being reached', () async {
      final manager = TestOidcUserManager()
        ..signInFailure = http.ClientException('offline');

      await expectLater(
        _authenticate(manager),
        throwsA(isA<ProviderUnreachable>()),
      );
    });
  });

  group('who the user is', () {
    Future<AuthNotifier> following(TestOidcUserManager manager) async {
      final notifier = AuthNotifier(manager: manager, config: _config);
      addTearDown(notifier.dispose);
      await notifier.ready;
      return notifier;
    }

    test('is read from the ID token', () async {
      final notifier = await following(
        TestOidcUserManager(
          user: await testOidcUser(
            claims: {
              'sub': 'player',
              'email': 'player@band.test',
              'roles': {'score_viewer': {}, 'score_editor': {}},
            },
          ),
        ),
      );

      expect(notifier.value?.id, 'player');
      expect(notifier.value?.email, 'player@band.test');
      expect(notifier.value?.isScoreViewer, isTrue);
      expect(notifier.value?.isScoreEditor, isTrue);
    });

    test('without roles may do nothing', () async {
      final notifier = await following(
        TestOidcUserManager(
          user: await testOidcUser(claims: {'sub': 'player'}),
        ),
      );

      expect(notifier.value?.roles, isEmpty);
      expect(notifier.value?.isScoreViewer, isFalse);
    });

    test('is followed as they sign in', () async {
      final manager = TestOidcUserManager();
      final notifier = await following(manager);
      expect(notifier.value, isNull);

      manager.changeTo(await testOidcUser(claims: {'sub': 'player'}));
      await Future<void>.delayed(Duration.zero);

      expect(notifier.value?.id, 'player');
    });
  });
}
