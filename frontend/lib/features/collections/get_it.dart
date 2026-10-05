import 'package:get_it/get_it.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/collections/api.dart';
import 'package:score/features/collections/repository.dart';
import 'package:score/features/sembast/local_store.dart';

extension CollectionsGetItExtensions on GetIt {
  void registerCollections() {
    registerLazySingletonAsync<CollectionsApi>(
      () async => CollectionsApi(config: (await getAsync<Config>()).api, client: get()),
    );

    registerLazySingletonAsync<CollectionsRepository>(
      () async {
        final repository = CollectionsRepository(
          store: await getAsync<LocalStore>(),
          api: await getAsync<CollectionsApi>(),
          oidc: await getAsync<OidcApi>(),
        );
        await repository.init();
        return repository;
      },
      dispose: (repository) => repository.dispose(),
    );
  }
}
