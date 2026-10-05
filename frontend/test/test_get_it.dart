import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:score/config.dart';
import 'package:score/features/auth/auth.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:score/features/settings/settings.dart';
import 'package:score/features/sync/sync.dart';
import 'package:score/get_it.dart';

extension TestGetItExtensions on GetIt {
  /// The app over a store that lives in memory, signed in as [user], with an
  /// API and a provider at addresses that go nowhere: for a test that draws
  /// the pages over what is on the device, without starting the app.
  ///
  /// Registered in a scope of its own, which [GetIt.popScope] undoes; the
  /// loggers registered for every test stay.
  Future<void> registerForTesting({UserInfo? user}) async {
    pushNewScope();
    registerLazySingletonAsync<Config>(
      () async => Config(
        oidc: OidcConfig.fromJson(json: {
          'clientId': 'test',
          'nativeClientId': 'test',
          'issuer': 'https://auth.invalid',
          'redirectUri': 'http://localhost:3000/',
          'authorizationEndpoint': 'https://auth.invalid/authorize',
          'tokenEndpoint': 'https://auth.invalid/token',
          'userInfoEndpoint': 'https://auth.invalid/userinfo',
          'healthzEndpoint': 'https://auth.invalid/healthz',
          'rolesKey': 'roles',
        }),
        api: ApiConfig(baseUrl: Uri.parse('https://api.invalid/')),
      ),
    );
    registerLazySingletonAsync(() => LocalStore.inMemory());
    registerLazySingleton(() => http.Client());
    registerFeatures();

    await getAsync<Settings>();
    await getAsync<Sync>();
    (await getAsync<Auth>()).user = user;
  }
}
