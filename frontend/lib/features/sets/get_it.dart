import 'package:get_it/get_it.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:score/features/sets/api.dart';
import 'package:score/features/sets/repository.dart';

extension SetsGetItExtensions on GetIt {
  void registerSets() {
    registerLazySingletonAsync<SetsApi>(
      () async => SetsApi((await getAsync<Config>()).api, client: get()),
    );

    registerLazySingletonAsync<SetsRepository>(
      () async {
        final repository = SetsRepository(
          await getAsync<LocalStore>(),
          await getAsync<SetsApi>(),
          await getAsync<OidcApi>(),
        );
        await repository.init();
        return repository;
      },
      dispose: (repository) => repository.dispose(),
    );
  }
}
