import 'package:flutter/material.dart' hide Title;
import 'package:provider/provider.dart';
import 'package:score/features/scores/widgets/search_field.dart';
import 'package:score/features/user/change_notifiers/roles_notifier.dart';
import 'package:score/features/user/change_notifiers/user_notifier.dart';
import 'package:score/home/widgets/create_new_score_button.dart';
import 'package:score/home/widgets/profile_button.dart';
import 'package:score/home/widgets/title.dart';
import 'package:score/router/app_router.gr.dart';

class LargeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LargeAppBar({
    super.key,
    required this.router,
  });

  final AppRouter router;

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
              const Title(),
              const SizedBox(width: 32),
              accessControlledButtons(),
              const SizedBox(width: 32),
              ProfileButton(router: router),
              const SizedBox(width: 32),
            ]),
          ),
        ),
      ),
    );
  }

  Widget accessControlledButtons() {
    Iterable<Widget> buildItems(RolesNotifier roles) sync* {
      if (roles.hasReadAccess) {
        yield const Expanded(child: SearchField());
        yield const SizedBox(width: 32);
      }
      if (roles.hasContributorAccess) {
        yield CreateNewScoreButton(router: router);
      }
    }

    return Consumer<RolesNotifier>(builder: (context, value, child) {
      return Expanded(
        child: Row(
          children: buildItems(value).toList(growable: false),
        ),
      );
    });
  }
}
