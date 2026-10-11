import 'package:get_it/get_it.dart';
import 'package:score/features/collections/behaviours/collections_engine.dart';
import 'package:score/features/collections/behaviours/delete_collection.dart';
import 'package:score/features/collections/behaviours/delete_collection_entry.dart';
import 'package:score/features/collections/behaviours/forget_collections.dart';
import 'package:score/features/collections/behaviours/save_collection.dart';
import 'package:score/features/collections/behaviours/save_collection_entry.dart';
import 'package:score/features/collections/behaviours/save_collection_entry_view.dart';
import 'package:score/features/collections/notifiers/collections_notifier.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/collections/storage/collections_store.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/features/sync/storage/sync_holds_store.dart';
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
      () async => CollectionsStore(client: (await getAsync<Databases>()).data),
    );

    registerLazySingletonAsync<CollectionsEngine>(() async {
      final engine = CollectionsEngine(
        logger: logger('Sync'),
        adapter: CollectionsAdapter(
          logger: logger('Collections'),
          store: await getAsync<CollectionsStore>(),
          holds: await getAsync<SyncHoldsStore>(),
          api: await getAsync<CollectionsApi>(),
        ),
      );
      await engine.init();
      return engine;
    });

    registerNotifier(
      () async => CollectionsNotifier(
        store: await getAsync<CollectionsStore>(),
        holds: await getAsync<SyncHoldsStore>(),
        engine: await getAsync<CollectionsEngine>(),
      ),
    );

    registerFactory(() => SaveCollection(monitor: get(), engine: get()));
    registerFactory(() => SaveCollectionEntry(monitor: get(), engine: get()));
    registerFactory(() => DeleteCollectionEntry(monitor: get(), engine: get()));
    registerFactory(
      () => SaveCollectionEntryView(monitor: get(), engine: get()),
    );
    registerFactory(() => DeleteCollection(monitor: get(), engine: get()));
    registerFactory(() => ForgetCollections(monitor: get(), engine: get()));
  }
}
