import 'package:get_it/get_it.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/features/scores/behaviours/download_score.dart';
import 'package:score/features/scores/behaviours/get_music_xml.dart';
import 'package:score/features/scores/behaviours/get_score.dart';
import 'package:score/features/scores/behaviours/mark_score_viewed.dart';
import 'package:score/features/scores/behaviours/pick_music_xml_file.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/behaviours/upload_score.dart';
import 'package:score/features/scores/notifiers/is_syncing_scores_notifier.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/storage/scores_api.dart';
import 'package:score/features/scores/storage/scores_database.dart';
import 'package:score/notifiers/get_it.dart';
import 'package:score/storage/clients.dart';
import 'package:score/storage/databases.dart';

extension ScoresGetItExtensions on GetIt {
  void registerScores() {
    registerLazySingletonAsync<ScoresApi>(
      () async => ScoresApi(clientFactory: await getAsync<ApiClientFactory>()),
    );

    registerLazySingletonAsync(
      () async => ScoresDatabase(client: (await getAsync<Databases>()).data),
    );
    registerNotifier(
      () async => ScoresNotifier(store: await getAsync<ScoresDatabase>()),
    );

    registerFactory(() => CacheScore(monitor: get(), db: get()));
    registerFactory(() => CacheMusicXml(monitor: get(), files: get()));

    registerLazySingleton(
      () => IsSyncingScoresNotifier(),
      dispose: (notifier) => notifier.dispose(),
    );
    registerFactory(
      () => SyncScores(
        monitor: get(),
        logger: logger('Scores'),
        db: get(),
        api: get(),
        syncDates: get(),
        authNotifier: get(),
        isSyncing: get(),
      ),
    );
    registerFactory(
      () => GetScore(monitor: get(), api: get(), db: get(), cache: get()),
    );
    registerFactory(
      () => GetMusicXml(
        monitor: get(),
        logger: logger('Scores'),
        files: get(),
        api: get(),
        cache: get(),
      ),
    );
    registerFactory(
      () => UploadScore(
        monitor: get(),
        logger: logger('Scores'),
        documents: get(),
        db: get(),
        api: get(),
        cacheScore: get(),
        cacheMusicXml: get(),
      ),
    );
    registerFactory(
      () => MarkScoreViewed(monitor: get(), store: get(), getScore: get()),
    );
    registerFactory(() => DownloadScore(monitor: get()));
    registerFactory(() => PickMusicXmlFile(monitor: get()));
  }
}
