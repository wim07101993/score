import 'package:get_it/get_it.dart';
import 'package:score/features/auth/auth.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/collections/api.dart';
import 'package:score/features/collections/repository.dart';
import 'package:score/features/scores/api.dart';
import 'package:score/features/scores/repository.dart';
import 'package:score/features/sets/api.dart';
import 'package:score/features/sets/repository.dart';
import 'package:score/features/sync/sync.dart';

extension SyncGetItExtensions on GetIt {
  void registerSync() {
    registerLazySingletonAsync<Sync>(
      () async => Sync(
        await getAsync<Auth>(),
        await getAsync<OidcApi>(),
        await getAsync<ScoresApi>(),
        await getAsync<SetsApi>(),
        await getAsync<CollectionsApi>(),
        await getAsync<ScoresRepository>(),
        await getAsync<SetsRepository>(),
        await getAsync<CollectionsRepository>(),
      ),
    );
  }
}
