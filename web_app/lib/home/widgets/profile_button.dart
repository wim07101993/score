import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hawk/hawk.dart';
import 'package:provider/provider.dart';
import 'package:score/features/user/behaviours/logout.dart';
import 'package:score/globals.dart';
import 'package:score/router/app_router.gr.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({
    super.key,
    required this.router,
  });

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context)!;
    return PopupMenuButton(
      iconSize: theme.appBarTheme.actionsIconTheme?.size,
      icon: FaIcon(
        FontAwesomeIcons.userLarge,
        color: theme.appBarTheme.foregroundColor,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          child: Text(s.accountSettings),
          onTap: () => router.push(const ProfileRoute()),
        ),
        PopupMenuItem(
          child: Text(s.logout),
          onTap: () => context.read<EventHub>().send(const LogoutEvent()),
        ),
      ],
    );
  }
}
