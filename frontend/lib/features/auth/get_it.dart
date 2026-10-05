import 'package:get_it/get_it.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/auth.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/collections/repository.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:score/features/sets/repository.dart';

extension AuthGetItExtensions on GetIt {
  void registerAuth() {
    registerLazySingletonAsync<OidcApi>(
      () async => OidcApi(
        (await getAsync<Config>()).oidc,
        await getAsync<LocalStore>(),
        client: get(),
      ),
    );

    registerLazySingletonAsync<Auth>(
      () async => Auth(
        await getAsync<OidcApi>(),
        await getAsync<SetsRepository>(),
        await getAsync<CollectionsRepository>(),
      ),
      dispose: (auth) => auth.dispose(),
    );
  }
}
