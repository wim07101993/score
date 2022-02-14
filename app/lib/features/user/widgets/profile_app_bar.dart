import 'package:flutter/material.dart';
import 'package:score/features/user/widgets/log_out_button.dart';
import 'package:score/globals.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProfileAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size(double.infinity, 100);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return AppBar(
      title: Text(s.profile),
      actions: const [
        LogOutButton(),
      ],
    );
  }
}
