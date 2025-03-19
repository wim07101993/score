import 'package:auto_route/auto_route.dart';
import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/scores/behaviours/search_scores.dart';
import 'package:score/features/scores/score.dart';
import 'package:score/routing/app_router.gr.dart';
import 'package:score/shared/widgets/exceptions.dart';

class ScoreSearchBar extends StatefulWidget {
  const ScoreSearchBar({super.key});

  @override
  State<ScoreSearchBar> createState() => _ScoreSearchBarState();
}

class _ScoreSearchBarState extends State<ScoreSearchBar> {
  late Future<SearchScores> futureSearchScores = GetIt.I.getAsync();

  Future<List<Score>> searchScores(String searchText) async {
    final searchScores = await futureSearchScores;
    final result = await searchScores(searchText);
    if (!mounted) {
      return [];
    }
    return result.when(
      (exception) {
        showUnknownErrorDialog(context);
        return [];
      },
      (scores) => scores,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SearchAnchor.bar(
      suggestionsBuilder: (context, controller) async {
        final scores = await searchScores(controller.text);
        return scores.map((score) => _scoreSuggestion(context, theme, score));
      },
    );
  }

  Widget _scoreSuggestion(BuildContext context, ThemeData theme, Score score) {
    return ListTile(
      title: Text(score.work?.title ?? score.movement?.title ?? score.id),
      subtitle: Text(
        [...score.creators.composers, ...score.creators.lyricists].join(', '),
      ),
      onTap: () => AutoRouter.of(context).push(ScoreRoute(scoreId: score.id)),
    );
  }
}
