import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/change_notifiers/user/user_notifier.dart';
import 'package:score/globals.dart';

class WelcomeTitle extends StatelessWidget {
  const WelcomeTitle({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    return Consumer<UserNotifier>(builder: (context, user, widget) {
      return Text(
        s.welcomeTitle(user.user?.displayName ?? ''),
        style: theme.appBarTheme.titleTextStyle?.copyWith(
          color: theme.appBarTheme.foregroundColor,
        ),
      );
    });
  }
}
