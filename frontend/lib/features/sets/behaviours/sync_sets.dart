import 'package:score/features/sets/models.dart';
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
}) extends Syncer<ScoreSet> {
  this
    : super(
        db: db,
        api: api,
        syncDateKey: key,
        copyUpdate: (existing, updated) => updated,
      );

  static const key = 'sets';
}
