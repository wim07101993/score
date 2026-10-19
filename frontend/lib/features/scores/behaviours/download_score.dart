import 'dart:async';
import 'dart:convert';

import 'package:behaviour/behaviour.dart';
import 'package:score/features/files/file_saver.dart';
import 'package:score/features/scores/models/score.dart';

class const DownloadScoreParams({
  required final String musicXml,
  required final String scoreId,
  required final String title,
}) {}

class DownloadScore({
  required super.monitor,
}) extends Behaviour<DownloadScoreParams, void> {
  @override
  String get description => 'downloading score';

  @override
  Future<void> action(
    DownloadScoreParams input,
    BehaviourTrack? track,
  ) async {
    final title = input.title.trim();
    final name = title.isEmpty
        ? input.scoreId
        : title.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_');
    await saveFile(
      bytes: utf8.encode(input.musicXml),
      mimeType: Score.mediaType,
      filename: '$name.musicxml',
    );
  }
}
