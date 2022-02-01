import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';
import 'package:score/features/user/widgets/sign_in_page.dart';

class SignedIn extends StatelessWidget {
  const SignedIn({
    Key? key,
    required this.builder,
  }) : super(key: key);

  final Widget Function(BuildContext context, UserNotifier user) builder;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserNotifier>(builder: (context, user, widget) {
      return Navigator(
        pages: [
          MaterialPage(child: builder(context, user)),
          if (user.value == null) const SignInPage(),
        ],
        onPopPage: (route, result) => route.didPop(result),
      );
    });
  }
}
