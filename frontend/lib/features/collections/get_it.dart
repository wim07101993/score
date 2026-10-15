import 'package:get_it/get_it.dart';
import 'package:score/features/collections/behaviours/delete_collection.dart';
import 'package:score/features/collections/behaviours/delete_collection_entry.dart';
import 'package:score/features/collections/behaviours/get_collection.dart';
import 'package:score/features/collections/behaviours/save_collection.dart';
import 'package:score/features/collections/behaviours/save_collection_entry.dart';
import 'package:score/features/collections/behaviours/save_collection_entry_view.dart';
import 'package:score/features/collections/behaviours/sync_collections.dart';
import 'package:score/features/collections/notifiers/collections_notifier.dart';
import 'package:score/features/collections/notifiers/is_syncing_collections_notifier.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/collections/storage/collections_database.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/notifiers/get_it.dart';
import 'package:score/storage/clients.dart';
import 'package:score/storage/databases.dart';

extension CollectionsGetItExtensions on GetIt {
  void registerCollections() {
    registerLazySingletonAsync<CollectionsApi>(
      () async => CollectionsApi(
        clientFactory: await getAsync<ApiClientFactory>(),
      ),
    );

    registerLazySingletonAsync(
      () async =>
          CollectionsDatabase(client: (await getAsync<Databases>()).data),
    );

    registerNotifier(
      () async =>
          CollectionsNotifier(store: await getAsync<CollectionsDatabase>()),
    );

    registerLazySingleton(
      () => IsSyncingCollectionsNotifier(),
      dispose: (notifier) => notifier.dispose(),
    );
    registerFactory(
      () => SyncCollections(
        monitor: get(),
        logger: logger('Collections'),
        db: get(),
        api: get(),
        syncDates: get(),
        authNotifier: get(),
        isSyncing: get(),
      ),
    );
    registerFactory(
      () => FetchCollection(monitor: get(), api: get(), db: get()),
    );
    registerFactory(
      () => GetCollection(monitor: get(), db: get(), api: get(), fetch: get()),
    );
    registerFactory(
      () => SaveCollection(monitor: get(), api: get(), db: get()),
    );
    registerFactory(
      () => SaveCollectionEntry(
        monitor: get(),
        api: get(),
        db: get(),
        fetch: get(),
      ),
    );
    registerFactory(
      () => DeleteCollectionEntry(monitor: get(), api: get(), fetch: get()),
    );
    registerFactory(
      () => SaveCollectionEntryView(
        monitor: get(),
        api: get(),
        db: get(),
        fetch: get(),
      ),
    );
    registerFactory(
      () => DeleteCollection(monitor: get(), api: get(), db: get()),
    );
  }
}
