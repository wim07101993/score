import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:score/shared/data/firebase/firestore/firestore_extensions.dart';
import 'package:score/shared/data/firebase/firestore/firestore_model_field_names.dart';
import 'package:score/shared/data/firebase/firestore/query_extensions.dart';
import 'package:score/shared/models/score.dart';

class GetRecentScores extends BehaviourWithoutInput<List<Score>> {
  GetRecentScores({
    required this.firestore,
    required this.auth,
    super.monitor,
  });

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  @override
  String get description => 'getting recent scores';

  @override
  Future<List<Score>> action(BehaviourTrack? track) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      return [];
    }

    final accessHistory = await firestore
        .scoreAccessHistory(currentUser.uid)
        .limit(12)
        .items
        .then((items) => items.map((item) => item.scoreId).toList());

    return firestore.scoresCollection
        .where(ScoreFields.id, whereIn: accessHistory)
        .items;
  }

  @override
  FutureOr<Exception> onCatch(
    Object e,
    StackTrace stacktrace,
    BehaviourTrack? track,
  ) {
    return Exception();
  }
}
