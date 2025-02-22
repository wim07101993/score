import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:cbl/cbl.dart';
import 'package:grpc/grpc.dart';
import 'package:score/features/scores/score.dart';
import 'package:score/shared/api/generated/google/protobuf/timestamp.pb.dart';
import 'package:score/shared/api/generated/searcher.pbgrpc.dart'
    show GetScoresRequest, SearcherClient;
import 'package:score/shared/api/generated/searcher.pbgrpc.dart' as api;

class FetchScoreChanges extends Behaviour<FetchScoreChangesParams, void> {
  FetchScoreChanges({
    required super.monitor,
    required this.searcherClient,
    required this.scores,
  });

  final SearcherClient searcherClient;
  final Collection scores;

  @override
  FutureOr<void> action(
    FetchScoreChangesParams input,
    BehaviourTrack? track,
  ) async {
    final lastChangedTimestamp = await _getLastChangedTimestamp(scores);
    final responseStream = searcherClient.getScores(
      GetScoresRequest(
        changedSince: lastChangedTimestamp != null
            ? Timestamp.fromDateTime(lastChangedTimestamp)
            : null,
      ),
      options: CallOptions(
        metadata: {'Authorization': 'Bearer ${input.authToken}'},
      ),
    );

    await for (final page in responseStream) {
      for (final score in page.scores) {
        final existing = await scores.typedDocument<Score>(score.id);
        final doc = _convertApiScoreToDbScore(
          score,
          existing != null && existing.isFavourite,
        );
        await scores.saveTypedDocument(doc).withConcurrencyControl();
      }
    }
  }
}

class FetchScoreChangesParams {
  const FetchScoreChangesParams({
    required this.authToken,
  });

  final String authToken;
}

Future<DateTime?> _getLastChangedTimestamp(Collection scoresCollection) async {
  final resultSet = await const QueryBuilder()
      .select(
        SelectResult.expression(
          Expression.property(Score.lastChangeTimestampPropertyName),
        ),
      )
      .from(DataSource.collection(scoresCollection))
      .orderBy(
        Ordering.property(Score.lastChangeTimestampPropertyName).descending(),
      )
      .limit(Expression.integer(1))
      .execute();

  final results = await resultSet.allResults();
  return results.firstOrNull
      ?.toPlainMap()[Score.lastChangeTimestampPropertyName] as DateTime?;
}

MutableScore _convertApiScoreToDbScore(api.Score score, bool isFavourite) {
  return MutableScore(
    id: score.id,
    work: Work(
      title: score.work.title,
      number: score.work.number,
    ),
    movement: Movement(
      title: score.movement.title,
      number: score.movement.number,
    ),
    creators: Creators(
      composers: score.creators.composers,
      lyricists: score.creators.lyricists,
    ),
    instruments: score.instruments,
    languages: score.languages,
    tags: score.tags,
    lastChangeTimestamp: score.lastChangeTimestamp.toDateTime(),
    isFavourite: isFavourite,
  );
}
