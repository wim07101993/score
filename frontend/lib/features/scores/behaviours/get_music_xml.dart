import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:logging/logging.dart';
import 'package:score/features/scores/storage/score_documents.dart';
import 'package:score/features/scores/storage/scores_api.dart';

class GetMusicXml({
  super.monitor,
  required final Logger logger,
  required final ScoreDocuments files,
  required final ScoresApi api,
  required final CacheMusicXml cache,
}) extends Behaviour<String, String?> {
  @override
  String get description => 'reading a score';

  @override
  Future<String?> action(String scoreId, BehaviourTrack? track) async {
    final doc = await files.read(scoreId);
    if (doc != null) {
      return doc;
    }

    if (!await api.canBeReached()) {
      return null;
    }

    final musicXml = await api.getScoreMusicXml(scoreId);
    if (musicXml == null) {
      return null;
    }

    // saving to the filesystem can happen in the background
    unawaited(Future(() => cache((scoreId, musicXml))));
    return musicXml;
  }
}

class CacheMusicXml({
  super.monitor,
  required final ScoreDocuments files,
}) extends Behaviour<(String scoreId, String musicXml), void> {
  @override
  String get description => 'cache musicxml';

  @override
  Future<void> action(
    (String scoreId, String musicXml) input,
    BehaviourTrack? track,
  ) {
    return files.write(input.$1, input.$2);
  }
}
