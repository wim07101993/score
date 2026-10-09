import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:score/features/scores/storage/score_documents.dart';
import 'package:score/features/scores/storage/scores_database.dart';

class ForgetScore({
  super.monitor,
  required final ScoresDatabase scores,
  required final ScoreDocuments files,
}) extends Behaviour<String, void> {
  @override
  String get description => 'forgetting about score';

  @override
  Future<void> action(String input, BehaviourTrack? track) async {
    await scores.remove(input);
    // A device put away between the two is left with a document nothing
    // lists: see `ForgetUnreferencedDocuments`.
    await files.remove(input);
  }
}
