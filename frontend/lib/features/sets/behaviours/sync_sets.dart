import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sets/storage/sets_database.dart';
import 'package:score/features/sync/models.dart';

class SyncSets({
  super.monitor,
  required super.logger,
  required super.syncDates,
  required SetsDatabase db,
  required SetsApi api,
}) extends Sync<ScoreSet> {
  this
    : super(
        db: db,
        api: api,
        syncDateKey: key,
        copyUpdate: (existing, updated) => updated,
      );

  static const key = 'sets';
}
