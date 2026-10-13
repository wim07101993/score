import 'package:get_it/get_it.dart';
import 'package:score/features/auth/notifiers/auth_notifier.dart';
import 'package:score/features/collections/behaviours/sync_collections.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/sets/behaviours/sync_sets.dart';
import 'package:score/features/sync/storage/sync_dates_store.dart';
import 'package:score/features/sync/sync_engine.dart';
import 'package:score/storage/databases.dart';

extension SyncGetItExtensions on GetIt {
  void registerSync() {
    registerLazySingletonAsync(
      () async => SyncDatesStore(client: (await getAsync<Databases>()).data),
    );
    registerLazySingletonAsync(
      () async => SyncEngine(
        userInfo: await getAsync<AuthNotifier>(),
        syncers: () => [
          get<SyncScores>(),
          get<SyncSets>(),
          get<SyncCollections>(),
        ],
      ),
      dispose: (engine) => engine.dispose(),
    );
  }
}
