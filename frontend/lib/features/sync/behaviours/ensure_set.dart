import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/behaviours/sets_engine.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sync/behaviours/update_sets.dart';

/// The set with the given id, syncing the sets first when it is not on this
/// device: a link into a set can be followed on a device that has not synced
/// since it was shared. Null when it is not there even then.
class EnsureSet({
  super.monitor,
  required final SetsEngine engine,
  required final UpdateSets updateSets,
}) extends Behaviour<String, ScoreSet?> {
  @override
  String get description => 'making sure a set is on this device';

  @override
  Future<ScoreSet?> action(String setId, BehaviourTrack? track) async {
    final known = engine.get(setId);
    if (known != null) {
      return known;
    }
    await updateSets.action(track);
    return engine.get(setId);
  }
}
