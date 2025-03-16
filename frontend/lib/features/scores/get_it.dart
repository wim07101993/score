import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:libsql_dart/libsql_dart.dart';
import 'package:score/features/logging/get_it.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/score_syncer.dart';

void registerScoreDependencies() {
  GetIt.I.registerLazySingletonAsync(
    () async => SyncScores(
      monitor: GetIt.I(),
      database: await GetIt.I.getAsync<LibsqlClient>(),
      searcherClient: GetIt.I(),
      logger: GetIt.I.logger('SyncScores'),
    ),
  );
  GetIt.I.registerLazySingletonAsync(
    () async => ScoreSyncer(
      bindings: WidgetsFlutterBinding.ensureInitialized(),
      userManager: await GetIt.I.getAsync(),
    ),
  );
}
