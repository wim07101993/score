import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:libsql_dart/libsql_dart.dart';
import 'package:score/features/scores/db_extensions.dart';
import 'package:score/l10n/arb/app_localizations.dart';

@RoutePage()
class ScoreScreen extends StatelessWidget {
  const ScoreScreen({
    super.key,
    @PathParam('id') required this.scoreId,
  });

  final String scoreId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: FutureBuilder(
          future: GetIt.I
              .getAsync<LibsqlClient>()
              .then((database) => database.getScore(scoreId)),
          builder: (context, snapshot) {
            final score = snapshot.data;
            if (score == null) {
              return const Column(children: [CircularProgressIndicator()]);
            }
            final title = score.work?.title ?? score.movement?.title;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null && title.isNotEmpty)
                  Text(
                    title,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                if (score.tags.isNotEmpty)
                  Text(score.tags.join(', '), textAlign: TextAlign.center),
                if (score.creators.composers.isNotEmpty)
                  Text(
                    '${s.scoreComposersLabel}: ${score.creators.composers.join(', ')}',
                    textAlign: TextAlign.right,
                  ),
                if (score.creators.lyricists.isNotEmpty)
                  Text(
                    '${s.scoreLyricistsLabel}: ${score.creators.lyricists.join(', ')}',
                    textAlign: TextAlign.right,
                  ),
              ],
            );
          }),
    );
  }
}
