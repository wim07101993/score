import 'package:get_it/get_it.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:score/features/sets/api.dart';
import 'package:score/features/sets/repository.dart';

extension SetsGetItExtensions on GetIt {
  void registerSets() {
    registerLazySingletonAsync<SetsApi>(
      () async => SetsApi(config: (await getAsync<Config>()).api, client: get()),
    );

    registerLazySingletonAsync<SetsRepository>(
      () async {
        final repository = SetsRepository(
          store: await getAsync<LocalStore>(),
          api: await getAsync<SetsApi>(),
          oidc: await getAsync<OidcApi>(),
        );
        await repository.init();
        return repository;
      },
      dispose: (repository) => repository.dispose(),
    );
  }
}
