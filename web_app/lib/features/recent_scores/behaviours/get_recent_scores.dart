import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:score/shared/data/models/score.dart';

class GetRecentScores extends BehaviourWithoutInput<List<Score>> {
  GetRecentScores({
    required this.firestore,
    super.monitor,
  });

  final FirebaseFirestore firestore;

  @override
  String get description => 'getting recent scores';

  @override
  Future<List<Score>> action(BehaviourTrack? track) {
    // TODO: implement onCatch
    throw UnimplementedError();
  }

  @override
  FutureOr<Exception> onCatch(
      Object e, StackTrace stacktrace, BehaviourTrack? track) {
    // TODO: implement onCatch
    throw UnimplementedError();
  }
}
