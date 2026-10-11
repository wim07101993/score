import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:oidc/oidc.dart';
import 'package:score/config.dart';
import 'package:score/features/scores/storage/score_documents.dart';
import 'package:score/get_it.dart';
import 'package:score/storage/databases.dart';

import 'test_oidc.dart';

extension TestGetItExtensions on GetIt {
  /// The app over a store that lives in memory, signed in as [user], with an
  /// API and a provider at addresses that go nowhere: for a test that draws
  /// the pages over what is on the device, without starting the app.
  ///
  /// Registered in a scope of its own, which [GetIt.popScope] undoes; the
  /// loggers registered for every test stay.
  Future<void> registerForTesting({Map<String, Object?>? user}) async {
    pushNewScope();
    registerLazySingletonAsync<Config>(
      () async => Config(
        oidc: OidcConfig.fromJson({
          'discoveryEndpoint':
              'https://auth.invalid/.well-known/openid-configuration',
          'healthzEndpoint': 'https://auth.invalid/healthz',
          'rolesKey': 'roles',
          'client': {
            'clientId': 'test',
            'redirectUri': 'http://localhost:3000/redirect.html',
          },
        }),
        api: ApiConfig(baseUrl: Uri.parse('https://api.invalid/')),
      ),
    );
    registerLazySingletonAsync(() => Databases.inMemory());
    registerLazySingletonAsync<ScoreDocuments>(
      () async => InMemoryScoreDocuments(),
    );
    registerLazySingleton(() => http.Client());
    registerFeatures();
    unregister<OidcUserManager>();
    registerLazySingletonAsync<OidcUserManager>(
      () async => TestOidcUserManager(
        user: user == null ? null : await testOidcUser(claims: user),
      ),
    );

    await resolveDependencies();
  }
}
