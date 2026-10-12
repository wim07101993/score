import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sets/storage/sets_database.dart';

class GetSet({
  super.monitor,
  required final SetsDatabase db,
  required final SetsApi api,
  required final FetchSet fetch,
}) extends Behaviour<String, ScoreSet?> {
  @override
  String get description => 'making sure a set is on this device';

  @override
  Future<ScoreSet?> action(String setId, BehaviourTrack? track) async {
    final existing = await db.get(setId);
    if (existing != null) {
      return existing.deletedAt == null ? existing : null;
    }
    if (!await api.canBeReached()) {
      return null;
    }
    return fetch.action(setId, track);
  }
}

class FetchSet({
  super.monitor,
  required final SetsApi api,
  required final SetsDatabase db,
}) extends Behaviour<String, ScoreSet?> {
  @override
  String get description => 'fetching a set';

  @override
  Future<ScoreSet?> action(String setId, BehaviourTrack? track) async {
    final set = await api.getSet(setId);
    if (set == null) {
      await db.remove(setId);
      return null;
    }
    await db.put(set);
    return set.deletedAt == null ? set : null;
  }
}
