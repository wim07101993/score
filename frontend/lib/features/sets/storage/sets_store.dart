import 'package:score/features/sets/models.dart';
import 'package:score/storage/record_store.dart';

/// The sets this device keeps, what is still owed about them included.
class SetsStore({
  required super.client,
}) extends SembastStore<ScoreSet> {
  this
    : super(
        storeName: 'sets',
        fromJson: ScoreSet.fromJson,
        toJson: (value) => value.toJson(),
        idOf: (value) => value.id,
      );
}
