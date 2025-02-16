import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:cbl/cbl.dart';
import 'package:score/features/scores/score.dart';

class GetLastSyncTime extends BehaviourWithoutInput<DateTime?> {
  GetLastSyncTime({
    required super.monitor,
    required this.database,
  });

  final Collection database;

  @override
  FutureOr<DateTime?> action(BehaviourTrack? track) async {
    final query = const QueryBuilder()
        .select(
          SelectResult.expression(
            Expression.property(Score.lastChangeTimestampPropertyName),
          ),
        )
        .from(DataSource.collection(database))
        .orderBy(
          Ordering.property(Score.lastChangeTimestampPropertyName).descending(),
        )
        .limit(Expression.integer(1));

    final resultSet = await query.execute();
    final results = await resultSet.allResults();
    return results.firstOrNull
        ?.toPlainMap()[Score.lastChangeTimestampPropertyName] as DateTime?;
  }
}
