import 'package:score/features/scores/models.dart';
import 'package:score/storage/record_store.dart';
import 'package:sembast/sembast.dart';

class ScoresDatabase({
  required super.client,
}) extends SembastStore<Score> {
  this
    : super(
        storeName: 'scores',
        fromJson: Score.fromJson,
        toJson: (value) => value.toJson(),
        idOf: (value) => value.id,
      );

  Future<List<Score>> getScoresWithId(List<String> ids) async {
    final set = await store.find(
      client,
      finder: Finder(filter: Filter.inList(Score.idFieldKey, ids)),
    );
    return set
        .map((record) => Score.fromJson(record.value))
        .toList(growable: false);
  }
}
