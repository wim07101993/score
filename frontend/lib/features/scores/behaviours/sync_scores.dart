import 'package:behaviour/behaviour.dart';
import 'package:logging/logging.dart';
import 'package:score/features/scores/models.dart';
import 'package:score/features/scores/storage/score_documents.dart';
import 'package:score/features/scores/storage/scores_api.dart';
import 'package:score/features/scores/storage/scores_database.dart';
import 'package:score/features/sync/storage/sync_dates_store.dart';

class SyncScores({
  super.monitor,
  required final Logger logger,
  required final ScoreDocuments documents,
  required final ScoresDatabase db,
  required final ScoresApi api,
  required final SyncDatesStore syncDates,
}) extends BehaviourWithoutInput<void> {
  /// What the scores' sync date is kept under: see [SyncDatesStore].
  static const syncDateKey = 'scores';

  static Future<void> _currentSync = Future.value();

  @override
  String get description => 'syncing the scores';

  @override
  Future<void> action(BehaviourTrack? track) {
    return _currentSync = _currentSync.then((_) => sync());
  }

  Future<void> sync() async {
    final lastSync = await syncDates.lastSyncedAt(syncDateKey);
    final changedScores = await api.listScores(
      // avoid rounding errors on fetch timestamps
      since: lastSync.subtract(const Duration(seconds: 2)),
    );

    final existingScores = await db.getScoresWithId(
      changedScores.map((score) => score.id).toList(growable: false),
    );

    final scoresToSave = List<Score>.empty(growable: true);
    for (final score in changedScores) {
      final existing = existingScores
          .where((s) => s.id == score.id)
          .firstOrNull;
      scoresToSave.add(
        existing == null ? score : score.copyLocalOnlyFields(existing),
      );
    }

    await db.putAll(scoresToSave);

    // On the server's clock rather than this device's: a device whose clock
    // runs ahead would otherwise start the next window after changes the
    // server has yet to make.
    if (changedScores.isEmpty) {
      return;
    }
    final newest = changedScores
        .map((score) => score.lastChangedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    await syncDates.keepLastSyncedAt(syncDateKey, newest);
  }
}
