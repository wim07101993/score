import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:cbl/cbl.dart';
import 'package:score/features/scores/score.dart';
import 'package:score/shared/api/generated/google/protobuf/timestamp.pb.dart';
import 'package:score/shared/api/generated/searcher.pbgrpc.dart'
    show GetScoresRequest, SearcherClient;

class UpdateScores extends BehaviourWithoutInput<void> {
  UpdateScores({
    required super.monitor,
    required this.searcher,
    required this.database,
  });

  final SearcherClient searcher;
  final Collection database;

  static Future<void>? fetchingFuture;

  @override
  FutureOr<void> action(BehaviourTrack? track) async {
    return fetchingFuture ??= _action().then((_) => fetchingFuture = null);
  }

  Future<void> _action() async {
    final resultSet = await lastChangeQuery(database).execute();
    final results = await resultSet.allResults();
    final lastChangeTimeStamp = results.firstOrNull
        ?.toPlainMap()[Score.lastChangeTimestampPropertyName] as DateTime?;

    final stream = searcher.getScores(
      GetScoresRequest(
        changedSince: lastChangeTimeStamp == null
            ? null
            : Timestamp.fromDateTime(lastChangeTimeStamp),
      ),
    );
    await stream.forEach((scorePage) {
      final scores = scorePage.scores
          .map(
            (s) => MutableScore(
              id: s.id,
              title: s.title,
              composers: s.composers,
              lyricists: s.lyricists,
              instruments: s.instruments,
              isFavourite: s.isFavourite,
              lastChangeTimestamp: s.lastChangeTimestamp.toDateTime(),
            ),
          )
          .toList(growable: false);

      for (final score in scores) {
        database.saveTypedDocument(score).withConcurrencyControl();
      }
    });
  }

  static Query lastChangeQuery(Collection collection) {
    return const QueryBuilder()
        .select(
          SelectResult.expression(
            Expression.property(Score.lastChangeTimestampPropertyName),
          ),
        )
        .from(DataSource.collection(collection))
        .orderBy(
          Ordering.property(Score.lastChangeTimestampPropertyName).descending(),
        )
        .limit(Expression.integer(1));
  }
}
