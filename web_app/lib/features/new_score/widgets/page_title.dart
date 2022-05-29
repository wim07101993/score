import 'package:flutter/material.dart';
import 'package:score/globals.dart';

class PageTitle extends StatelessWidget {
  const PageTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context)!;
    return Text(
      s.newScoreTitle,
      style: theme.textTheme.headline4,
      textAlign: TextAlign.center,
    );
  }
}
