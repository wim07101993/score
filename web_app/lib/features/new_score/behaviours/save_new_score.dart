import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/data/firebase/exceptions/permission_denied_exception.dart';
import 'package:score/features/new_score/data/firestore_extensions.dart';
import 'package:score/features/new_score/models/draft_score.dart';

class SaveNewScore extends Behaviour<DraftScore, void> {
  SaveNewScore({
    required this.firestore,
    super.monitor,
  });

  final FirebaseFirestore firestore;

  @override
  Future<void> action(DraftScore input, BehaviourTrack? track) async {
    return firestore.saveDraftScore(input);
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
