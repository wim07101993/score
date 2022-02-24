import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';

class Title extends StatelessWidget {
  const Title({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<UserNotifier>(builder: (context, user, widget) {
      return Text(
        'Score',
        style: theme.appBarTheme.titleTextStyle?.copyWith(
          color: theme.appBarTheme.foregroundColor,
        ),
      );
    });
  }
}
