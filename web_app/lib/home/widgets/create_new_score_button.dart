import 'package:flutter/material.dart';
import 'package:score/router/app_router.gr.dart';

class CreateNewScoreButton extends StatelessWidget {
  const CreateNewScoreButton({
    super.key,
    required this.router,
  });

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onPressed,
      iconSize: theme.appBarTheme.actionsIconTheme?.size,
      color: theme.appBarTheme.foregroundColor,
      icon: const Icon(Icons.add),
    );
  }

  void onPressed() {
    router.push(const CreateNewScoreRoute());
  }
}