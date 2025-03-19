import 'package:behaviour/behaviour.dart';
import 'package:flutter_fox_logging/flutter_fox_logging.dart';
import 'package:hive_ce/hive.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/scores/score.dart';
import 'package:score/shared/api/generated/google/protobuf/timestamp.pb.dart';
import 'package:score/shared/api/generated/searcher.pbgrpc.dart' as grpc;

class SyncScores extends Behaviour<OidcUser, void> {
  SyncScores({
    required super.monitor,
    required this.scoreBox,
    required this.lastChangedAtBox,
    required this.searcherClient,
    required this.logger,
  });

  final LazyBox<Score> scoreBox;
  final Box<DateTime> lastChangedAtBox;
  final grpc.SearcherClient searcherClient;
  final Logger logger;

  @override
  Future<void> action(OidcUser user, BehaviourTrack? track) async {
    final lastChangedAt = lastChangedAtBox.values.firstOrNull;
    final responseStream = searcherClient.getScores(
      grpc.GetScoresRequest(
        changedSince: lastChangedAt == null
            ? null
            : Timestamp.fromDateTime(lastChangedAt),
      ),
    );

    await for (final page in responseStream) {
      for (final score in page.scores) {
        final original = await scoreBox.get(score.id);
        if (original == null) {
          await scoreBox.put(score.id, Score.fromGrpc(score));
        } else {
          await scoreBox.put(
            score.id,
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
