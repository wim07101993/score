import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/shared/data/firebase/exceptions/permission_denied_exception.dart';
import 'package:score/shared/data/firebase/firestore/scores_collection.dart';
import 'package:score/shared/models/score.dart';

class SaveNewScore extends Behaviour<Score, void> {
  SaveNewScore({
    required this.firestore,
    super.monitor,
  });

  final FirebaseFirestore firestore;

  @override
  Future<void> action(Score input, BehaviourTrack? track) async {
    await firestore.addScore(input);
  }

  @override
  String get description => 'saving draft score';

  @override
  FutureOr<Exception> onCatch(
    Object e,
    StackTrace stacktrace,
    BehaviourTrack? track,
  ) {
    if (e is FirebaseException && e.code == "permission-denied") {
      return const PermissionDeniedException();
    }
    return Exception();
  }
}
