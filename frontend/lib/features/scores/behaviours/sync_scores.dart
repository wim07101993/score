import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/notifiers/is_syncing_scores_notifier.dart';
import 'package:score/features/scores/storage/scores_api.dart';
import 'package:score/features/scores/storage/scores_database.dart';
import 'package:score/features/sync/behaviours/syncer.dart';

class SyncScores({
  super.monitor,
  required super.logger,
  required super.syncDates,
  required super.authNotifier,
  required ScoresDatabase db,
  required ScoresApi api,
  required IsSyncingScoresNotifier isSyncing,
}) extends Syncer<Score> {
  this
    : super(
        db: db,
        api: api,
        syncDateKey: 'scores',
        copyUpdate: (existing, updated) =>
            updated.copyLocalOnlyFields(existing),
        isSyncing: isSyncing,
      );
}
