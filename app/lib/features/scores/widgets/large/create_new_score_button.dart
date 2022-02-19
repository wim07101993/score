import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:score/router/app_router.gr.dart';

class CreateNewScoreButton extends StatelessWidget {
  const CreateNewScoreButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: () => onPressed(context),
      iconSize: theme.appBarTheme.actionsIconTheme?.size,
      color: theme.appBarTheme.foregroundColor,
      icon: const Icon(Icons.add),
    );
  }

  void onPressed(BuildContext context) {
    context.pushRoute(const CreateNewScoreRoute());
  }
}
