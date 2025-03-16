import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:libsql_dart/libsql_dart.dart';
import 'package:score/features/scores/db_extensions.dart';
import 'package:score/features/scores/score.dart';

class ScoreSearchBar extends StatelessWidget {
  const ScoreSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SearchAnchor.bar(
      suggestionsBuilder: (context, controller) => GetIt.I
          .getAsync<LibsqlClient>()
          .then((db) => db
              .search(controller.text)
              .take(100)
              .map(_scoreSuggestion)
              .toList()),
    );
  }

  Widget _scoreSuggestion(Score score) {
    return Text(
      score.work?.title ?? score.movement?.title ?? score.id,
    );
  }
}
