import 'package:behaviour/behaviour.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/storage/scores_api.dart';
import 'package:score/features/sync/behaviours/api_sync.dart';
import 'package:score/features/sync/behaviours/one_at_a_time.dart';

/// Squares the scores with the API, when it is there to be asked.
class UpdateScores({
  super.monitor,
  required final ScoresApi api,
  required final SyncScores syncScores,
  required final ApiSync apiSync,
  required final OneAtATime oneAtATime,
}) extends BehaviourWithoutInput<void> {
  @override
  String get description => 'updating the scores';

  @override
  Future<void> action(BehaviourTrack? track) => oneAtATime(
    'scores',
    () => apiSync(
      what: 'syncing the scores',
      apiCanBeReached: api.canBeReached,
      sync: () => syncScores.action(track),
    ),
  );
}
