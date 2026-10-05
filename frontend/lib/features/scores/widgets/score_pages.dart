import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/score_detail_page.dart';

/// What is known about a score, how it is read, and a look at it.
///
/// [scoreId] is `new` for a score that is about to be uploaded, and
/// [ScoreDetailPage.paper] for an entry that is played from paper.
@RoutePage()
class ScorePage extends StatelessWidget {
  const ScorePage({
    super.key,
    @PathParam('scoreId') required this.scoreId,
    @QueryParam('set') this.setId,
    @QueryParam('collection') this.collectionId,
    @QueryParam('entry') this.entryId,
  });

  final String scoreId;
  final String? setId;
  final String? collectionId;
  final String? entryId;

  @override
  Widget build(BuildContext context) => ScoreDetailPage(
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
class PerformScorePage extends StatelessWidget {
  const PerformScorePage({
    super.key,
    @PathParam('scoreId') required this.scoreId,
    @QueryParam('set') this.setId,
    @QueryParam('collection') this.collectionId,
    @QueryParam('entry') this.entryId,
    this.handover,
  });

  final String scoreId;
  final String? setId;
  final String? collectionId;
  final String? entryId;

  /// How the details page had it, when that is where the score is being
  /// played from; an address opened on its own has none.
  final ScoreReadingHandover? handover;

  @override
  Widget build(BuildContext context) => ScoreDetailPage(
        scoreId: scoreId,
        setId: setId,
        collectionId: collectionId,
        entryId: entryId,
        performing: true,
        handover: handover,
      );
}
