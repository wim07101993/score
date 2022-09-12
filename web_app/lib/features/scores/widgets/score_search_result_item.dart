import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_logging_extensions/flutter_logging_extensions.dart';
import 'package:score/router/app_router.gr.dart';
import 'package:score/shared/models/score.dart';

class ScoreSearchResultItem extends StatelessWidget {
  const ScoreSearchResultItem({
    super.key,
    required this.score,
  });

  final Score score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = score.subtitle;
    return Card(
      margin: const EdgeInsets.all(24),
      child: InkWell(
        onTap: () => AutoRouter.of(context).push(
          ScoreDetailRoute(score: score),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(score.title, style: theme.textTheme.headline5),
              if (subtitle != null) Text(subtitle),
              creators(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget creators(ThemeData theme) {
    final creators = [
      ...score.composers,
      ...score.arrangements.mapMany((a) => a.lyricists),
      ...score.arrangements.mapMany((a) => a.arrangers),
    ];
    switch (creators.length) {
      case 0:
        return const Text('');
      case 1:
        return Text(creators[0]);
      default:
        return Text(
          creators.join(', '),
          style: theme.textTheme.bodyText2,
        );
    }
  }
}
