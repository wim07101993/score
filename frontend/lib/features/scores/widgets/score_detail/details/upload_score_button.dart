import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/scores/behaviours/pick_music_xml_file.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';
import 'package:score/features/scores/behaviours/upload_score.dart';
import 'package:score/widgets/exceptions.dart';
import 'package:uuid/uuid.dart';

class const UploadScoreButton({
  super.key,
  required final String? scoreId,
  required final void Function(String scoreId) onUploaded,
}) extends StatelessWidget {
  Future<void> uploadScore(BuildContext context) async {
    final pickResult = await GetIt.I<PickMusicXmlFile>()();
    if (!context.mounted) {
      return;
    }

    late final String musicxml;
    switch (pickResult) {
      case Failed(reason: final exception):
        // TODO proper message
        await showExceptionDialog(
          context,
          title: 'failed to pick musicxml file',
          message: exception.toString(),
        );
        return;
      case Success(value: final value):
        if (value == null) {
          return;
        }
        musicxml = value;
    }

    final scoreId = this.scoreId ?? const Uuid().v4();
    final uploadResult = await GetIt.I<UploadScore>()((scoreId, musicxml));
    if (!context.mounted) {
      return;
    }

    switch (uploadResult) {
      case Failed(reason: final exception):
        // TODO proper message
        await showExceptionDialog(
          context,
          title: 'failed to upload musicxml file',
          message: exception.toString(),
        );
        return;
      case Success():
        unawaited(Future(() => GetIt.I<SyncScores>()()));
        onUploaded(scoreId);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.upload_file),
      label: Text(scoreId != null ? 'Replace this score' : 'Upload a score'),
      onPressed: () => uploadScore(context),
    );
  }
}
