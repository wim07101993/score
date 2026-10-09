import 'package:behaviour/behaviour.dart';
import 'package:score/features/sync/behaviours/update_collections.dart';
import 'package:score/features/sync/behaviours/update_scores.dart';
import 'package:score/features/sync/behaviours/update_sets.dart';

/// Squares the scores, the sets and the collections with the API, one after
/// the other: what the player asks for with the sync button.
class SyncEverything({
  super.monitor,
  required final UpdateScores updateScores,
  required final UpdateSets updateSets,
  required final UpdateCollections updateCollections,
}) extends BehaviourWithoutInput<void> {
  @override
  String get description => 'syncing everything';

  @override
  Future<void> action(BehaviourTrack? track) async {
    await updateScores.action(track);
    await updateSets.action(track);
    await updateCollections.action(track);
  }
}
