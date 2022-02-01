import 'package:flutter/material.dart';
import 'package:score/features/scores/widgets/large/profile_button.dart';
import 'package:score/features/scores/widgets/large/search_field.dart';
import 'package:score/features/scores/widgets/large/welcome_title.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({Key? key}) : super(key: key);

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
          child: Row(children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: WelcomeTitle(),
            ),
            Expanded(child: SearchField()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: ProfileButton(),
            ),
          ]),
        ),
      ),
    );
  }
}
