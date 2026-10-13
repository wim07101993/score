import 'package:score/features/scores/models/score.dart';
import 'package:score/features/sync/models/syncable.dart';
import 'package:score/storage/record_store.dart';

class ScoresDatabase({
  required super.client,
}) extends SembastStore<Score> implements SyncEntityDatabase<Score> {
  this
    : super(
        storeName: 'scores',
        fromJson: Score.fromJson,
        toJson: (value) => value.toJson(),
        idOf: (value) => value.id,
        idFieldKey: Score.idFieldKey,
      );
}
