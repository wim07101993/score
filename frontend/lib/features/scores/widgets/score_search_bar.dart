import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:libsql_dart/libsql_dart.dart';
import 'package:score/features/scores/db_extensions.dart';
import 'package:score/features/scores/score.dart';
import 'package:score/routing/app_router.gr.dart';

class ScoreSearchBar extends StatelessWidget {
  const ScoreSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SearchAnchor.bar(
      suggestionsBuilder: (context, controller) {
        final theme = Theme.of(context);
        return GetIt.I.getAsync<LibsqlClient>().then((db) => db
            .search(controller.text)
            .take(100)
            // ignore: use_build_context_synchronously
            .map((score) => _scoreSuggestion(context, theme, score))
            .toList());
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
