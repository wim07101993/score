import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:logging/logging.dart';
import 'package:score/features/scores/behaviours/get_music_xml.dart';
import 'package:score/features/scores/behaviours/get_score.dart';
import 'package:score/features/scores/score_details.dart';
import 'package:score/features/scores/storage/score_documents.dart';
import 'package:score/features/scores/storage/scores_api.dart';
import 'package:score/features/scores/storage/scores_database.dart';

class UploadScore({
  super.monitor,
  required final Logger logger,
  required final ScoreDocuments documents,
  required final ScoresDatabase db,
  required final ScoresApi api,
  required final CacheScore cacheScore,
  required final CacheMusicXml cacheMusicXml,
}) extends Behaviour<(String scoreId, String musicXml), void> {
  @override
  String get description => 'uploading a score';

  @override
  Future<void> action(
    (String scoreId, String musicXml) input,
    BehaviourTrack? track,
  ) async {
    final scoreId = input.$1;
    final musicXml = input.$2;
    track?.addAttribute('score', scoreId);

    final local = readScoreDetails(
      scoreId: scoreId,
      musicXml: musicXml,
      lastChangedAt: DateTime.now().toUtc(),
    );
    if (local != null) {
      await cacheScore(local);
    }
    unawaited(Future(() => cacheMusicXml((scoreId, musicXml))));

    if (await api.canBeReached()) {
      await api.putScore(scoreId, musicXml);
      final score = await api.getScore(scoreId);
      if (score == null) {
        throw Exception('failed to read back the score which was just saved');
      }
      unawaited(Future(() => cacheScore(score)));
    }
  }
}

// TODO: add a lastFetchedAt to all scores to allow for granular updates
// TODO: add a lastFetchedAt to all files (separate db table)
