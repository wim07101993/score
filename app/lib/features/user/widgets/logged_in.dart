import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';
import 'package:score/features/user/widgets/login_screen.dart';

class LoggedIn extends StatelessWidget {
  const LoggedIn({
    Key? key,
    required this.builder,
  }) : super(key: key);

  final Widget Function(BuildContext context, UserNotifier user) builder;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserNotifier>(
      builder: (context, user, oldWidget) => Navigator(
        pages: [
          MaterialPage(child: builder(context, user)),
          if (user.value == null) const MaterialPage(child: LoginScreen()),
        ],
        onPopPage: (route, result) => route.didPop(result),
      ),
    );
  }
}
