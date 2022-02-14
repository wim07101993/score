import 'package:flutter/widgets.dart';
import 'package:score/features/user/models/user.dart';
import 'package:score/globals.dart';

class UserType extends StatelessWidget {
  const UserType({
    Key? key,
    required this.user,
  }) : super(key: key);

  final User user;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return user.when(
      guest: (guest) => Text(s.guest),
      standardUser: (standardUser) => const SizedBox(),
      contributor: (contributor) => Text(s.contributor),
      admin: (admin) => Text(s.admin),
    );
  }
}
