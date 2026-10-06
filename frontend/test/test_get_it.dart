import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:score/background.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/features/scores/storage/score_documents.dart';
import 'package:score/get_it.dart';
import 'package:score/storage/databases.dart';

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
        oidc: OidcConfig.fromJson(logger: Logger('test'), json: {
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
    registerLazySingletonAsync(() => Databases.inMemory());
    registerLazySingletonAsync<ScoreDocuments>(
      () async => InMemoryScoreDocuments(),
    );
    registerLazySingleton(() => http.Client());
    registerLazySingleton(() => Background(logger: Logger('test')));
    registerFeatures();

    await resolveDependencies();
    await get<OidcApi>().keepUserInfo(user);
    // Until the notifier has heard what was just kept, the pages would be
    // drawn for nobody.
    while (get<AuthNotifier>().user?.subject != user?.subject) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}
