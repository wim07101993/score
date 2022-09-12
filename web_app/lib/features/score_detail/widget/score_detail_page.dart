import 'package:flutter/material.dart';
import 'package:score/shared/models/score.dart';

class ScoreDetailPage extends StatelessWidget {
  const ScoreDetailPage({
    super.key,
    required this.score,
  });

  final Score score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(score.title, style: theme.textTheme.headline4);
  }
}
