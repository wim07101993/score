import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/auth/behaviours/log_in.dart';
import 'package:score/features/auth/google_user_manager.dart';
import 'package:score/features/auth/user.dart';

void registerAuthDependencies() {
  GetIt.I.registerLazySingletonAsync(() async {
    final manager = GoogleUserManager.lazy(
      // TODO: add correct client id
      clientCredentials: const OidcClientAuthentication.none(clientId: 'score'),
      store: OidcMemoryStore(),
      settings: OidcUserManagerSettings(
        // TODO: use correct redirect uri
        redirectUri: Uri.parse('https://wimvanlaer.com/score/oauth-redirect'),
      ),
    );
    await manager.init();
    return manager;
  });
  GetIt.I.registerFactory(
    () => UserListenable(
      googleUserManager: GetIt.I(),
    ),
  );

  GetIt.I.registerFactory(() => LogIn(monitor: GetIt.I()));
}
