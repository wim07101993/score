import 'package:get_it/get_it.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/features/sets/behaviours/delete_set.dart';
import 'package:score/features/sets/behaviours/delete_set_entry.dart';
import 'package:score/features/sets/behaviours/get_set.dart';
import 'package:score/features/sets/behaviours/save_set.dart';
import 'package:score/features/sets/behaviours/save_set_entry.dart';
import 'package:score/features/sets/behaviours/save_set_entry_view.dart';
import 'package:score/features/sets/behaviours/sync_sets.dart';
import 'package:score/features/sets/notifiers/sets_notifier.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sets/storage/sets_database.dart';
import 'package:score/notifiers/get_it.dart';
import 'package:score/storage/clients.dart';
import 'package:score/storage/databases.dart';

extension SetsGetItExtensions on GetIt {
  void registerSets() {
    registerLazySingletonAsync<SetsApi>(
      () async => SetsApi(clientFactory: await getAsync<ApiClientFactory>()),
    );

    registerLazySingletonAsync(
      () async => SetsDatabase(client: (await getAsync<Databases>()).data),
    );

    registerNotifier(
      () async => SetsNotifier(store: await getAsync<SetsDatabase>()),
    );

    registerFactory(
      () => SyncSets(
        monitor: get(),
        logger: logger('Sets'),
        db: get(),
        api: get(),
        syncDates: get(),
        authNotifier: get(),
      ),
    );
    registerFactory(() => FetchSet(monitor: get(), api: get(), db: get()));
    registerFactory(
      () => GetSet(monitor: get(), db: get(), api: get(), fetch: get()),
    );
    registerFactory(() => SaveSet(monitor: get(), api: get(), db: get()));
    registerFactory(
      () => SaveSetEntry(monitor: get(), api: get(), db: get(), fetch: get()),
    );
    registerFactory(
      () => DeleteSetEntry(monitor: get(), api: get(), fetch: get()),
    );
    registerFactory(
      () => SaveSetEntryView(
        monitor: get(),
        api: get(),
        db: get(),
        fetch: get(),
      ),
    );
    registerFactory(() => DeleteSet(monitor: get(), api: get(), db: get()));
  }
}
