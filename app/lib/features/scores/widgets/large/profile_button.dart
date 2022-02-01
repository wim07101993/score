import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: () => onPressed(context),
      iconSize: 32,
      color: theme.appBarTheme.foregroundColor,
      icon: const FaIcon(FontAwesomeIcons.userAlt),
    );
  }

  void onPressed(BuildContext context) {
    // TODO navigate to profile page
    print('TODO navigate to profile page');
  }
}
