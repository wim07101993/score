import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:score/router/app_router.gr.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: () => onPressed(context),
      iconSize: theme.appBarTheme.actionsIconTheme?.size,
      color: theme.appBarTheme.foregroundColor,
      icon: const FaIcon(FontAwesomeIcons.userAlt),
    );
  }

  void onPressed(BuildContext context) {
    context.pushRoute(const ProfileRoute());
  }
}
