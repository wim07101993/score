import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/auth/behaviours/log_in.dart';
import 'package:score/shared/stream_listenable.dart';

void registerAuthDependencies() {
  GetIt.I.registerLazySingletonAsync(() async {
    final manager = OidcUserManager.lazy(
      clientCredentials: const OidcClientAuthentication.none(
        clientId: '299540604398927877',
      ),
      discoveryDocumentUri: Uri.parse(
        'http://localhost:7003/.well-known/openid-configuration',
      ),
      store: OidcMemoryStore(),
      settings: OidcUserManagerSettings(
        redirectUri: Uri.parse('http://localhost:0/auth/login-callback'),
        postLogoutRedirectUri:
            Uri.parse('http://localhost:0/auth/logout-callback'),
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

  GetIt.I.registerFactory(
    () => LogIn(
      monitor: GetIt.I(),
      userManager: GetIt.I(),
    ),
  );
}
