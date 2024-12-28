import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:score/app_settings.dart';
import 'package:score/features/auth/behaviours/log_in.dart';
import 'package:score/features/auth/behaviours/log_out.dart';
import 'package:score/shared/stream_listenable.dart';

void registerAuthDependencies() {
  GetIt.I.registerLazySingletonAsync(() async {
    final manager = OidcUserManager.lazy(
      clientCredentials: OidcClientAuthentication.none(
        clientId: appSettings.auth.clientId,
      ),
      discoveryDocumentUri: appSettings.auth.discoveryDocumentUri,
      store: OidcMemoryStore(),
      settings: OidcUserManagerSettings(
        redirectUri: appSettings.auth.loginRedirectUri,
        postLogoutRedirectUri: appSettings.auth.postLogoutRedirectUri,
      ),
    );
    await manager.init();
    return manager;
  });
  GetIt.I.registerFactory<ValueListenable<OidcUser?>>(
    () => StreamListenable.nullable<OidcUser?>(
      stream: GetIt.I.get<OidcUserManager>().userChanges(),
    ),
  );

  GetIt.I.registerFactoryAsync(
    () async => LogIn(
      monitor: GetIt.I(),
      userManager: await GetIt.I.getAsync(),
    ),
  );
  GetIt.I.registerFactoryAsync(
    () async => LogOut(
      monitor: GetIt.I(),
      userManager: await GetIt.I.getAsync(),
    ),
  );
}
