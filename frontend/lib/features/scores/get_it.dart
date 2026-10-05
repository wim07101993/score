import 'package:get_it/get_it.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/scores/api.dart';
import 'package:score/features/scores/repository.dart';
import 'package:score/features/sembast/local_store.dart';

extension ScoresGetItExtensions on GetIt {
  void registerScores() {
    registerLazySingletonAsync<ScoresApi>(
      () async => ScoresApi((await getAsync<Config>()).api, client: get()),
    );

    registerLazySingletonAsync<ScoresRepository>(
      () async {
        final repository = ScoresRepository(
          await getAsync<LocalStore>(),
          await getAsync<ScoresApi>(),
          await getAsync<OidcApi>(),
        );
        await repository.init();
        return repository;
      },
      dispose: (repository) => repository.dispose(),
    );
  }
}
