import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/features/scores/models/score.dart';
import 'package:score/features/scores/widgets/score_detail/collection_score_detail_page.dart';
import 'package:score/features/scores/widgets/score_detail/score_detail_page.dart';
import 'package:score/features/scores/widgets/score_detail/set_score_detail_page.dart';

/// What is known about a score, how it is read, and a look at it.
///
/// [scoreId] is `new` for a score that is about to be uploaded, and
/// [Score.paperId] for an entry of a set that is played from paper.
@RoutePage()
class const ScorePage({
  super.key,
  @PathParam('scoreId') required final String scoreId,
  @QueryParam('set') final String? setId,
  @QueryParam('collection') final String? collectionId,
  @QueryParam('entry') final String? entryId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _detailPage(
    scoreId: scoreId,
    setId: setId,
    collectionId: collectionId,
    entryId: entryId,
  );
}

/// A score on the whole screen, to be played from.
///
/// Played from a set or a collection, [setId] or [collectionId] says which
/// and [entryId] which of its entries this is.
@RoutePage()
class const PerformScorePage({
  super.key,
  @PathParam('scoreId') required final String scoreId,
  @QueryParam('set') final String? setId,
  @QueryParam('collection') final String? collectionId,
  @QueryParam('entry') final String? entryId,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _detailPage(
    scoreId: scoreId,
    setId: setId,
    collectionId: collectionId,
    entryId: entryId,
    performing: true,
  );
}

Widget _detailPage({
  required String scoreId,
  required String? setId,
  required String? collectionId,
  required String? entryId,
  bool performing = false,
}) {
  if (entryId != null && setId != null) {
    return SetScoreDetailPage(
      scoreId: scoreId,
      setId: setId,
      entryId: entryId,
      performing: performing,
    );
  }
  if (entryId != null && collectionId != null) {
    return CollectionScoreDetailPage(
      scoreId: scoreId,
      collectionId: collectionId,
      entryId: entryId,
      performing: performing,
    );
  }
  return ScoreDetailPage(
    scoreId: scoreId == 'new' ? null : scoreId,
    performing: performing,
  );
}
