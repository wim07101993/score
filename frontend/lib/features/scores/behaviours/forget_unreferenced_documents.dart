import 'package:behaviour/behaviour.dart';
import 'package:score/features/scores/storage/score_documents.dart';
import 'package:score/features/scores/storage/scores_database.dart';

class ForgetUnreferencedDocuments({
  super.monitor,
  required final ScoresDatabase db,
  required final ScoreDocuments files,
}) extends BehaviourWithoutInput<void> {
  @override
  String get description => 'forgetting documents of scores that are gone';

  @override
  Future<void> action(BehaviourTrack? track) async {
    final scores = await db.getAll();
    final scoreIds = scores.map((score) => score.id).toSet();
    for (final id in await files.ids()) {
      if (!scoreIds.contains(id)) {
        await files.remove(id);
      }
    }
  }
}
