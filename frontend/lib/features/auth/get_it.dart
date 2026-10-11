import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:oidc_default_store/oidc_default_store.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/behaviours/authenticate.dart';
import 'package:score/features/auth/behaviours/can_connect_to_api.dart';
import 'package:score/features/auth/behaviours/can_connect_to_oidc_provider.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/notifiers/get_it.dart';

extension AuthGetItExtensions on GetIt {
  void registerAuth() {
    registerLazySingletonAsync<OidcUserManager>(
      () async {
        final config = await getAsync<Config>().then((config) => config.oidc);
        final clientConfig = config.clientConfig;

        final manager = OidcUserManager.lazy(
          discoveryDocumentUri: config.discoveryEndpoint,
          clientCredentials: OidcClientAuthentication.none(
            clientId: clientConfig.clientId,
          ),
          store: get(),
          settings: OidcUserManagerSettings(
            redirectUri: clientConfig.redirectUri,
            scope: config.scopes,
            supportOfflineAuth: true,
            options: const OidcPlatformSpecificOptions(
              android: OidcNativeOptionsAndroid(ephemeralBrowsing: true),
              ios: OidcNativeOptionsApple(
                prefersEphemeralWebBrowserSession: true,
              ),
              macos: OidcNativeOptionsApple(
                prefersEphemeralWebBrowserSession: true,
              ),
              windows: desktop,
              linux: desktop,
            ),
          ),
        );
        await manager.init();
        return manager;
      },
      dispose: (manager) => manager.dispose(),
    );
    registerLazySingleton<OidcStore>(() => OidcDefaultStore());
    registerFactory(
      () => Authenticate(
        monitor: get(),
        manager: get(),
        config: get<Config>().oidc,
        logger: logger('Auth'),
      ),
    );
    registerFactory(
      () => CanConnectToApi(
        monitor: get(),
        api: get(),
      ),
    );
    registerFactory(
      () => CanConnectToOidcProvider(
        monitor: get(),
        httpClient: get(),
        config: get<Config>().oidc,
      ),
    );
    registerNotifier(
      () async => AuthNotifier(
        manager: await getAsync<OidcUserManager>(),
        config: (await getAsync<Config>()).oidc,
      ),
    );
  }
}

const desktop = OidcPlatformSpecificOptions_Native(
  flowTimeoutSeconds: 5 * 60,
  successfulPageResponse: '''
<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><title>Signed in</title></head>
<body style="font-family: system-ui, sans-serif; text-align: center; padding: 4rem;">
  <h1>Signed in</h1>
  <p>You can close this tab and go back to Score.</p>
</body>
</html>
''',
);
