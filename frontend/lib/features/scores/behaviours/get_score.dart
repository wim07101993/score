import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:score/features/scores/models.dart';
import 'package:score/features/scores/storage/scores_api.dart';
import 'package:score/features/scores/storage/scores_database.dart';

class GetScore({
  super.monitor,
  required final ScoresApi api,
  required final ScoresDatabase db,
  required final CacheScore cache,
}) extends Behaviour<String, Score?> {
  @override
  String get description => 'making sure a score is on this device';

  @override
  Future<Score?> action(String scoreId, BehaviourTrack? track) async {
    final existing = await db.get(scoreId);
    if (existing != null) {
      return existing;
    }

    if (!await api.canBeReached()) {
      return null;
    }

    final score = await api.getScore(scoreId);
    if (score == null) {
      return null;
    }

    // saving to the db can happen in the background
    unawaited(Future(() => cache(score)));

    return score;
  }
}

class CacheScore({
  super.monitor,
  required final ScoresDatabase db,
}) extends Behaviour<Score, void> {
  @override
  String get description => 'cache score';

  @override
  Future<void> action(Score score, BehaviourTrack? track) async {
    await db.put(score);
  }
}
