import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:flutter/foundation.dart';
import 'package:libsql_dart/libsql_dart.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/scores/db_extensions.dart';
import 'package:score/features/scores/score.dart';
import 'package:score/shared/api/generated/google/protobuf/timestamp.pb.dart';
import 'package:score/shared/api/generated/searcher.pbgrpc.dart' as grpc;

class FetchScoresIfOld extends BehaviourWithoutInput<void> {
  FetchScoresIfOld({
    required super.monitor,
    required this.database,
    required this.user,
    required this.searcherClient,
  });

  final LibsqlClient database;
  final ValueListenable<OidcUser?> user;
  final grpc.SearcherClient searcherClient;

  @override
  Future<void> action(BehaviourTrack? track) async {
    final accessToken = user.value?.token.accessToken;
    if (accessToken == null) {
      return;
    }

    final lastSyncTime = await database.getLastSyncTime();
    final now = DateTime.now().toUtc();
    if ((now.difference(lastSyncTime)) < const Duration(minutes: 5)) {
      return;
    }

    final responseStream = searcherClient.getScores(
      grpc.GetScoresRequest(changedSince: Timestamp.fromDateTime(lastSyncTime)),
    );

    await for (final page in responseStream) {
      for (final score in page.scores) {
        final original = await database.getScore(score.id);
        if (original == null) {
          await database.insertScore(Score.fromGrpc(score));
        } else {
          await database.updateScore(
            Score(
              id: score.id,
              work: Work.fromGrpc(score.work),
              movement: Movement.fromGrpc(score.movement),
              creators: Creators.fromGrpc(score.creators),
              instruments: score.instruments,
              languages: score.languages,
              tags: score.tags,
              lastChangedAt: score.lastChangeTimestamp.toDateTime(),
              favouritedAt: original.favouritedAt,
            ),
          );
        }
      }
    }
  }
}
