import 'package:behaviour/behaviour.dart';
import 'package:score/features/scores/behaviours/get_score.dart';
import 'package:score/features/scores/storage/scores_database.dart';

class MarkScoreViewed({
  super.monitor,
  required final ScoresDatabase store,
  required final GetScore getScore,
}) extends Behaviour<String, void> {
  @override
  String get description => 'marking a score as looked at';

  @override
  Future<void> action(String scoreId, BehaviourTrack? track) async {
    final score = await getScore.action(scoreId, track);
    if (score == null) {
      return;
    }
    await store.put(score.copyWith(lastViewedAt: DateTime.now()));
  }
}
