import 'package:get_it/get_it.dart';
import 'package:score/config.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/features/sync/behaviours/api_sync.dart';
import 'package:score/features/sync/behaviours/check_connection.dart';
import 'package:score/features/sync/behaviours/ensure_collection.dart';
import 'package:score/features/sync/behaviours/ensure_set.dart';
import 'package:score/features/sync/behaviours/one_at_a_time.dart';
import 'package:score/features/sync/behaviours/sync_everything.dart';
import 'package:score/features/sync/behaviours/update_collections.dart';
import 'package:score/features/sync/behaviours/update_scores.dart';
import 'package:score/features/sync/behaviours/update_sets.dart';
import 'package:score/features/sync/storage/sync_dates_store.dart';
import 'package:score/features/sync/storage/sync_holds_store.dart';
import 'package:score/storage/databases.dart';

extension SyncGetItExtensions on GetIt {
  void registerSync() {
    registerLazySingletonAsync(
      () async => SyncHoldsStore(database: (await getAsync<Databases>()).data),
    );
    registerLazySingletonAsync(
      () async => SyncDatesStore(client: (await getAsync<Databases>()).data),
    );
    registerLazySingleton(() => OneAtATime());
    registerFactory(
      () => CheckConnection(
        monitor: get(),
        api: get(),
        manager: get(),
        config: get<Config>().oidc,
        client: get(),
      ),
    );
    registerFactory(
      () => ApiSync(logger: logger('Sync')),
    );

    registerFactory(
      () => UpdateScores(
        monitor: get(),
        api: get(),
        syncScores: get(),
        apiSync: get(),
        oneAtATime: get(),
      ),
    );
    registerFactory(
      () => UpdateSets(
        monitor: get(),
        api: get(),
        engine: get(),
        apiSync: get(),
        oneAtATime: get(),
      ),
    );
    registerFactory(
      () => UpdateCollections(
        monitor: get(),
        api: get(),
        engine: get(),
        apiSync: get(),
        oneAtATime: get(),
      ),
    );
    registerFactory(
      () => EnsureSet(monitor: get(), engine: get(), updateSets: get()),
    );
    registerFactory(
      () => EnsureCollection(
        monitor: get(),
        engine: get(),
        updateCollections: get(),
      ),
    );
    registerFactory(
      () => SyncEverything(
        monitor: get(),
        updateScores: get(),
        updateSets: get(),
        updateCollections: get(),
      ),
    );
  }
}
