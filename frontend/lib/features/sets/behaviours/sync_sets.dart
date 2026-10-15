import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/notifiers/is_syncing_sets_notifier.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sets/storage/sets_database.dart';
import 'package:score/features/sync/behaviours/syncer.dart';

class SyncSets({
  super.monitor,
  required super.logger,
  required super.syncDates,
  required super.authNotifier,
  required SetsDatabase db,
  required SetsApi api,
  required IsSyncingSetsNotifier isSyncing,
}) extends Syncer<ScoreSet> {
  this
    : super(
        db: db,
        api: api,
        syncDateKey: key,
        copyUpdate: (existing, updated) => updated,
        isSyncing: isSyncing,
      );

  static const key = 'sets';
}
