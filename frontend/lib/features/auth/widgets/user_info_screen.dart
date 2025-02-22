import 'package:auto_route/annotations.dart';
import 'package:behaviour/behaviour.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/auth/behaviours/log_out.dart';
import 'package:score/l10n/arb/app_localizations.dart';
import 'package:score/shared/widgets/exceptions.dart';

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
    result.when((exception) => showUnknownError(), (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.userInfoScreenTitle),
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
                // TODO cleanup
                const Text('USER INFO'),
                for (final key in user.userInfo.keys)
                  Text('$key: ${user.userInfo[key]}'),
                const Text('ATTRIBUTES'),
                for (final key in user.attributes.keys)
                  Text('$key: ${user.attributes[key]}'),
                const Text('AGGREGATED CLAIMS'),
                for (final key in user.aggregatedClaims.keys)
                  Text('$key: ${user.aggregatedClaims[key]}'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: logout,
                    child: Text(s.logoutButtonText),
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
