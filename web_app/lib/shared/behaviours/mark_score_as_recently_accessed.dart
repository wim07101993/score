import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:score/shared/data/firebase/firestore/firestore_extensions.dart';
import 'package:score/shared/models/score_access_history_item.dart';

class MarkScoreAssRecentlyAccessed extends Behaviour<String, void> {
  MarkScoreAssRecentlyAccessed({
    required this.firestore,
    required this.auth,
    required this.logger,
    super.monitor,
  });

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final Logger logger;

  @override
  Future<void> action(String input, BehaviourTrack? track) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      logger.w('cannot mark score as recently accessed when not logged in');
      return;
    }
    await firestore
        .scoreAccessHistoryCollection(input)
        .add(ScoreAccessHistoryItem(
          scoreId: input,
          accessDate: DateTime.now().toUtc(),
        ));
  }

  @override
  // TODO: implement description
  String get description => throw UnimplementedError();

  @override
  FutureOr<Exception> onCatch(
      Object e, StackTrace stacktrace, BehaviourTrack? track) {
    // TODO: implement onCatch
    throw UnimplementedError();
  }
}
