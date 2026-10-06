import 'package:get_it/get_it.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/features/sets/behaviours/delete_set.dart';
import 'package:score/features/sets/behaviours/delete_set_entry.dart';
import 'package:score/features/sets/behaviours/forget_sets.dart';
import 'package:score/features/sets/behaviours/save_set.dart';
import 'package:score/features/sets/behaviours/save_set_entry.dart';
import 'package:score/features/sets/behaviours/save_set_entry_view.dart';
import 'package:score/features/sets/behaviours/sets_engine.dart';
import 'package:score/features/sets/notifiers/sets_notifier.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sets/storage/sets_store.dart';
import 'package:score/features/sync/storage/sync_holds_store.dart';
import 'package:score/notifiers/get_it.dart';
import 'package:score/storage/databases.dart';

extension SetsGetItExtensions on GetIt {
  void registerSets() {
    registerLazySingletonAsync<SetsApi>(
      () async => SetsApi(config: (await getAsync<Config>()).api, client: get()),
    );

    registerLazySingletonAsync(
      () async => SetsStore(database: (await getAsync<Databases>()).data),
    );

    registerLazySingletonAsync<SetsEngine>(() async {
      final engine = SetsEngine(
        logger: logger('Sync'),
        adapter: SetsAdapter(
          logger: logger('Sets'),
          store: await getAsync<SetsStore>(),
          holds: await getAsync<SyncHoldsStore>(),
          api: await getAsync<SetsApi>(),
        ),
        oidc: await getAsync<OidcApi>(),
      );
      await engine.init();
      return engine;
    });

    registerNotifier(
      () async => SetsNotifier(
        store: await getAsync<SetsStore>(),
        holds: await getAsync<SyncHoldsStore>(),
        engine: await getAsync<SetsEngine>(),
      ),
    );

    registerFactory(() => SaveSet(monitor: get(), engine: get()));
    registerFactory(() => SaveSetEntry(monitor: get(), engine: get()));
    registerFactory(() => DeleteSetEntry(monitor: get(), engine: get()));
    registerFactory(() => SaveSetEntryView(monitor: get(), engine: get()));
    registerFactory(() => DeleteSet(monitor: get(), engine: get()));
    registerFactory(() => ForgetSets(monitor: get(), engine: get()));
  }
}
