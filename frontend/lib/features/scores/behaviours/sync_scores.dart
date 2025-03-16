import 'package:behaviour/behaviour.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:libsql_dart/libsql_dart.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/scores/db_extensions.dart';
import 'package:score/features/scores/score.dart';
import 'package:score/shared/api/generated/google/protobuf/timestamp.pb.dart';
import 'package:score/shared/api/generated/searcher.pbgrpc.dart' as grpc;

class SyncScores extends Behaviour<OidcUser, void> {
  SyncScores({
    required super.monitor,
    required this.database,
    required this.searcherClient,
    required this.logger,
  });

  final LibsqlClient database;
  final grpc.SearcherClient searcherClient;
  final Logger logger;

  @override
  Future<void> action(OidcUser user, BehaviourTrack? track) async {
    final responseStream = searcherClient.getScores(
      grpc.GetScoresRequest(
        changedSince: Timestamp.fromDateTime(
          await database.getLastSyncedScoreChangedAt(),
        ),
      ),
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
