import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:flutter/foundation.dart';
import 'package:libsql_dart/libsql_dart.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/scores/database_extensions.dart';
import 'package:score/shared/api/generated/google/protobuf/timestamp.pb.dart';
import 'package:score/shared/api/generated/searcher.pbgrpc.dart';

class FetchScoresIfOld extends BehaviourWithoutInput<void> {
  FetchScoresIfOld({
    required super.monitor,
    required this.database,
    required this.user,
    required this.searcherClient,
  });

  final LibsqlClient database;
  final ValueListenable<OidcUser?> user;
  final SearcherClient searcherClient;

  @override
  Future<void> action(BehaviourTrack? track) async {
    final accessToken = user.value?.token.accessToken;
    if (accessToken == null) {
      return;
    }

    final result = await database.query(Queries.getLastSyncTime);
    print(result);
    final lastSyncTime = DateTime(0);

    final now = DateTime.now().toUtc();
    if ((now.difference(lastSyncTime)) < const Duration(minutes: 5)) {
      return;
    }

    final responseStream = searcherClient.getScores(
      GetScoresRequest(changedSince: Timestamp.fromDateTime(lastSyncTime)),
    );

    await for (final page in responseStream) {
      for (final score in page.scores) {
        print(score);
      }
    }
  }
}
