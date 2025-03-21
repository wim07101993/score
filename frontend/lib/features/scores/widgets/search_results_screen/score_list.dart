import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/features/scores/score.dart';
import 'package:score/routing/app_router.gr.dart';

class ScoreList extends StatelessWidget {
  const ScoreList({
    super.key,
    required this.scores,
  });

  final List<Score> scores;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        if (index >= scores.length) {
          assert(index <= scores.length);
          return const SizedBox();
        }
        return ScoreListItem(score: scores[index]);
      },
    );
  }
}

class ScoreListItem extends StatelessWidget {
  const ScoreListItem({
    super.key,
    required this.score,
  });

  final Score score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => AutoRouter.of(context).push(ScoreRoute(scoreId: score.id)),
      child: Card(
        child: Row(
          spacing: 16,
          children: [
            const SizedBox(
              width: 60,
              height: 90,
              child: Placeholder(),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score.work?.title ??
                      score.movement?.title ??
                      score.work?.number ??
                      score.movement?.number ??
                      score.id,
                  style: theme.textTheme.labelLarge,
                ),
                Text(
                  [
                    ...score.creators.composers,
                    ...score.creators.lyricists,
                  ].join(', '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
