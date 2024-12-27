import 'package:auto_route/annotations.dart';
import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/auth/behaviours/log_out.dart';

@RoutePage()
class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({
    super.key,
  });

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  Future<void> logout() async {
    final logout = await GetIt.I.getAsync<LogOut>();
    final result = await logout();
    if (!mounted) {
      return;
    }
    result.when(
      (failure) => print(failure),
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TODO translate
        title: const Text('User info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<OidcUser?>(
          valueListenable: GetIt.I(),
          builder: (context, user, _) {
            if (user == null) {
              return const SizedBox();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                // TODO translate
                const Text('USER INFO'),
                for (final key in user.userInfo.keys)
                  Text('$key: ${user.userInfo[key]}'),
                // TODO translate
                const Text('ATTRIBUTES'),
                for (final key in user.attributes.keys)
                  Text('$key: ${user.attributes[key]}'),
                // TODO translate
                const Text('AGGREGATED CLAIMS'),
                for (final key in user.aggregatedClaims.keys)
                  Text('$key: ${user.aggregatedClaims[key]}'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: logout,
                    // TODO translate
                    child: const Text('LOG OUT'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
