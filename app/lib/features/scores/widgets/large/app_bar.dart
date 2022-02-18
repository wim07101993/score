import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:score/features/scores/widgets/large/add_score_button.dart';
import 'package:score/features/scores/widgets/large/profile_button.dart';
import 'package:score/features/scores/widgets/large/welcome_title.dart';
import 'package:score/features/user/change_notifiers/roles_notifier.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size(double.infinity, 100);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.appBarTheme.backgroundColor,
      elevation: 2,
      child: SafeArea(
        child: SizedBox(
          height: 100,
          child: Consumer<UserNotifier>(
            builder: (context, userNotifier, child) => Row(children: [
              const SizedBox(width: 32),
              const WelcomeTitle(),
              const Spacer(),
              Consumer<RolesNotifier>(
                builder: (context, value, child) => value.hasContributorAccess
                    ? const AddScoreButton()
                    : const SizedBox(),
              ),
              const SizedBox(width: 32),
              const ProfileButton(),
              const SizedBox(width: 32),
            ]),
          ),
        ),
      ),
    );
  }
}
