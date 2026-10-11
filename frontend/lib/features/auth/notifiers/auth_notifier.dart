import 'package:oidc/oidc.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/user_info.dart';
import 'package:score/notifiers/store_notifier.dart';

class AuthNotifier({
  required final OidcUserManager manager,
  required final OidcConfig config,
}) extends StreamNotifier<UserInfo?> {
  this : super(initial: null) {
    follow(
      manager.userChanges().map(
        (user) => user == null
            ? null
            : UserInfo(oidcUser: user, rolesKey: config.rolesKey),
      ),
    );
  }
}
