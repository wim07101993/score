import 'dart:async';
import 'dart:convert';

import 'package:behaviour/behaviour.dart';
import 'package:score/features/files/file_saver.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/models/score_view_settings.dart';
import 'package:score/features/scores/storage/score_documents.dart';
import 'package:score/features/scores/storage/scores_database.dart';
import 'package:songbird_musicxml/songbird_musicxml.dart';
import 'package:songbird_score/songbird_score.dart' as mxml;
import 'package:songbird_score/songbird_score.dart' hide Score;

class const DownloadScoreParams({
  required final mxml.Score scoreData,
  required final Score score,
  required final ScoreViewSettings view,
}) {}

class DownloadScore({
  required super.monitor,
  required final ScoresDatabase db,
  required final ScoreDocuments docs,
}) extends Behaviour<DownloadScoreParams, void> {
  @override
  String get description => 'downloading score';

  @override
  Future<void> action(
    DownloadScoreParams input,
    BehaviourTrack? track,
  ) async {
    final parts = input.scoreData.parts
        .where((part) => input.view.partVisibilities[part.id] != false)
        .toList(growable: false);

    final modifiedScore = input.scoreData.withParts(parts);
    ScoreEditor(modifiedScore).execute(
      TransposeCommand(
        interval: Interval.chromaticFromKey(
          input.view.transposition,
          modifiedScore.parts.firstOrNull
                  ?.contextAtMeasure(0)
                  .keyFor(allStaves) ??
              KeySignature.cMajor,
        ),
      ),
    );

    await saveFile(
      bytes: utf8.encode(const MusicXmlWriter().write(modifiedScore)),
      mimeType: Score.mediaType,
      filename: input.score.title.isNotEmpty
          ? input.score.title.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_')
          : input.score.id,
    );
  }
}
