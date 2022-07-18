import 'dart:async';

import 'package:algolia/algolia.dart';
import 'package:behaviour/behaviour.dart';
import 'package:score/shared/data/algolia/algolia_extensions.dart';
import 'package:score/shared/models/pagination_page.dart';
import 'package:score/shared/models/score.dart';

class SearchScoresParams {
  const SearchScoresParams({
    required this.searchString,
    required this.pageIndex,
  });

  final String searchString;
  final int pageIndex;
}

class SearchScores
    extends Behaviour<SearchScoresParams, PaginationPage<Score>> {
  SearchScores({
    required this.algolia,
    super.monitor,
  });

  final Algolia algolia;

  @override
  String get description => 'searching for scores';

  @override
  Future<PaginationPage<Score>> action(
    SearchScoresParams input,
    BehaviourTrack? track,
  ) {
    return algolia.searchScores(
      searchString: input.searchString,
      pageIndex: input.pageIndex,
      pageSize: 20,
    );
  }

  @override
  FutureOr<Exception> onCatch(
    Object e,
    StackTrace stacktrace,
    BehaviourTrack? track,
  ) {
    return e is Exception ? e : Exception();
  }
}
