import 'dart:async';
import 'dart:math';

import 'package:behaviour/behaviour.dart';
import 'package:hive_ce/hive.dart';
import 'package:score/features/scores/score.dart';

class SearchScores extends Behaviour<String, List<Score>> {
  SearchScores({
    super.monitor,
    required this.database,
  });

  final LazyBox<Score> database;

  @override
  FutureOr<List<Score>> action(String input, BehaviourTrack? track) async {
    if (input.isEmpty) {
      return [];
    }
    final distances = List<_ScoreDistance>.empty(growable: true);

    for (final scoreId in database.keys.cast<String>()) {
      final score = await database.get(scoreId);
      if (score == null) {
        continue;
      }

      distances.add(_ScoreDistance(score.calculateDistance(input), score));
    }

    distances.sort((a, b) => a.distance.compareTo(b.distance));
    return distances.map((wrapper) => wrapper.score).toList(growable: false);
  }
}

int levenshteinDistance(String s, String t) {
  final d = List.generate(s.length + 1, (_) => List.filled(t.length + 1, 0));
  for (var i = 0; i < d.length; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j < d[0].length; j++) {
    d[0][j] = j;
  }
  for (var j = 1; j <= t.length; j++) {
    for (var i = 1; i <= s.length; i++) {
      if (s[i - 1] == t[j - 1]) {
        d[i][j] = d[i - 1][j - 1];
      } else {
        final deletion = d[i - 1][j];
        final insertion = d[i][j - 1];
        final substitution = d[i - 1][j - 1];

        final m = min(deletion, min(insertion, substitution));
        d[i][j] = m + 1;
      }
    }
  }
  return d[s.length][t.length];
}

extension _ScoreExtensions on Score {
  double calculateDistance(String s) {
    final workTitle = work?.title;
    final workNumber = work?.number;
    final movementTitle = movement?.title;
    final movementNumber = movement?.number;
    return <double>[
      if (workTitle != null) levenshteinDistance(workTitle, s).toDouble(),
      if (workNumber != null) levenshteinDistance(workNumber, s) * 1.1,
      if (movementTitle != null)
        levenshteinDistance(movementTitle, s).toDouble(),
      if (movementNumber != null) levenshteinDistance(movementNumber, s) * 1.1,
      for (final lyricist in creators.lyricists)
        levenshteinDistance(lyricist, s).toDouble(),
      for (final composer in creators.composers)
        levenshteinDistance(composer, s).toDouble(),
      for (final instrument in instruments)
        levenshteinDistance(instrument, s) * 1.3,
      for (final tag in tags) levenshteinDistance(tag, s) * 1.2
    ].min;
  }
}

extension _ListExtensions<T> on List<double> {
  double get min {
    if (isEmpty) {
      return 0;
    }
    var val = this[0];
    for (var i = 1; i < length; i++) {
      if (this[i] < val) {
        val = this[i];
      }
    }
    return val;
  }
}

class _ScoreDistance {
  const _ScoreDistance(this.distance, this.score);

  final double distance;
  final Score score;
}
