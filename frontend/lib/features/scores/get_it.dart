import 'package:get_it/get_it.dart';
import 'package:score/behaviours/in_turn.dart';
import 'package:score/config.dart';
import 'package:score/features/observability/get_it.dart';
import 'package:score/features/scores/behaviours/ensure_score.dart';
import 'package:score/features/scores/behaviours/forget_gone_scores.dart';
import 'package:score/features/scores/behaviours/get_music_xml.dart';
import 'package:score/features/scores/behaviours/kept_scores.dart';
import 'package:score/features/scores/behaviours/mark_score_viewed.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/behaviours/upload_score.dart';
import 'package:score/features/scores/notifiers/scores_notifier.dart';
import 'package:score/features/scores/storage/scores_api.dart';
import 'package:score/features/scores/storage/scores_store.dart';
import 'package:score/notifiers/get_it.dart';
import 'package:score/storage/databases.dart';

extension ScoresGetItExtensions on GetIt {
  void registerScores() {
    registerLazySingletonAsync<ScoresApi>(
      () async => ScoresApi(config: (await getAsync<Config>()).api, client: get()),
    );

    registerLazySingletonAsync(
      () async => ScoresStore(database: (await getAsync<Databases>()).data),
    );
    registerNotifier(
      () async => ScoresNotifier(store: await getAsync<ScoresStore>()),
    );

    registerFactory(() => KeptScores(store: get(), documents: get()));
    // A sync and the search for what is gone take turns: see [InTurn].
    registerLazySingleton(() => InTurn(), instanceName: _scoreSyncs);

    registerFactory(
      () => SyncScores(
        monitor: get(),
        logger: logger('Scores'),
        documents: get(),
        kept: get(),
        api: get(),
        oidc: get(),
        turn: get(instanceName: _scoreSyncs),
      ),
    );
    registerFactory(
      () => ForgetGoneScores(
        monitor: get(),
        logger: logger('Scores'),
        kept: get(),
        api: get(),
        oidc: get(),
        turn: get(instanceName: _scoreSyncs),
      ),
    );
    registerFactory(
      () => EnsureScore(monitor: get(), kept: get(), api: get(), oidc: get()),
    );
    registerFactory(
      () => GetMusicXml(
        monitor: get(),
        logger: logger('Scores'),
        documents: get(),
        kept: get(),
        api: get(),
        oidc: get(),
        ensureScore: get(),
        background: get(),
      ),
    );
    registerFactory(
      () => UploadScore(
        monitor: get(),
        logger: logger('Scores'),
        documents: get(),
        kept: get(),
        api: get(),
        oidc: get(),
        ensureScore: get(),
      ),
    );
    registerFactory(
      () => MarkScoreViewed(monitor: get(), store: get(), ensureScore: get()),
    );
  }
}

const _scoreSyncs = 'scoreSyncs';
