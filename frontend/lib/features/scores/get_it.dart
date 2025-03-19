import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:score/features/logging/get_it.dart';
import 'package:score/features/scores/behaviours/search_scores.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/score.dart';
import 'package:score/features/scores/score_syncer.dart';

const _lastChangedAtBoxName = 'lastChangedAtBox';

void registerScoreDependencies() {
  GetIt.I.registerLazySingletonAsync(() async {
    final hive = await GetIt.I.getAsync<HiveInterface>();
    return hive.openLazyBox<Score>('scoresBox');
  });
  GetIt.I.registerLazySingletonAsync(
    () async {
      final hive = await GetIt.I.getAsync<HiveInterface>();
      return hive.openBox<DateTime>(_lastChangedAtBoxName);
    },
    instanceName: _lastChangedAtBoxName,
  );

  GetIt.I.registerLazySingletonAsync(
    () async {
      final futureScoresBox = GetIt.I.getAsync<LazyBox<Score>>();
      final futureLastChangedAtBox = GetIt.I.getAsync<Box<DateTime>>(
        instanceName: _lastChangedAtBoxName,
      );
      return SyncScores(
        monitor: GetIt.I(),
        scoreBox: await futureScoresBox,
        lastChangedAtBox: await futureLastChangedAtBox,
        searcherClient: GetIt.I(),
        logger: GetIt.I.logger('SyncScores'),
      );
    },
  );
  GetIt.I.registerLazySingletonAsync(() async => SearchScores());
  GetIt.I.registerLazySingletonAsync(
    () async => ScoreSyncer(
      bindings: WidgetsFlutterBinding.ensureInitialized(),
      userManager: await GetIt.I.getAsync(),
    ),
  );
}
