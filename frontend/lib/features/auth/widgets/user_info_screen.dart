import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';

@RoutePage()
class UserInfoScreen extends StatelessWidget {
  const UserInfoScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<OidcUser?>(
        valueListenable: GetIt.I(),
        builder: (context, user, _) {
          assert(user != null);

          return Column(
            children: [
              const Text('USER INFO'),
              for (final key in user!.userInfo.keys)
                Text('$key: ${user.userInfo[key]}'),
              const Text('ATTRIBUTES'),
              for (final key in user.attributes.keys)
                Text('$key: ${user.attributes[key]}'),
            ],
          );
        },
      ),
    );
  }
}
