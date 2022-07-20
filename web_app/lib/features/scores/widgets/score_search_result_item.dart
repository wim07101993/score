import 'package:flutter/material.dart';
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(score.title, style: theme.textTheme.headline5),
            if (subtitle != null) Text(subtitle),
            composers(theme),
          ],
        ),
      ),
    );
  }

  Widget composers(ThemeData theme) {
    if (score.composers.isEmpty) {
      return const Text('');
    }
    if (score.composers.length == 1) {
      return Text(score.composers[0]);
    }
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyText2,
        children: [
          ...score.composers
              .take(score.composers.length - 1)
              .map((composer) => TextSpan(text: '$composer, ')),
          TextSpan(text: score.composers.last),
        ],
      ),
    );
  }
}
