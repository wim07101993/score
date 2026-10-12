import 'package:score/features/sets/models.dart';
import 'package:score/features/sync/models.dart';
import 'package:score/storage/record_store.dart';

class SetsDatabase({
  required super.client,
}) extends SembastStore<ScoreSet> implements SyncEntityDatabase<ScoreSet> {
  this
    : super(
        storeName: 'sets',
        fromJson: ScoreSet.fromJson,
        toJson: (value) => value.toJson(),
        idOf: (value) => value.id,
        idFieldKey: ScoreSet.idFieldKey,
      );
}
