import 'package:score/features/auth/storage/auth_store.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/notifiers/store_notifier.dart';

typedef AuthState = ({
  UserInfo? user,
  bool userIsFromThisDevice,
  String? authProblem,
});

/// Who uses this device, as far as it knows.
///
/// Every page decides what to show from the roles in [user], and listens to
/// this to hear when that changes.
class AuthNotifier({
  required final OidcApi oidc,
  required final AuthStore authStore,
}) extends StoreNotifier<AuthState> {
  this
    : super(
        initial: (user: null, userIsFromThisDevice: false, authProblem: null),
      ) {
    follow(
      oidc.watchKeptUserInfo(),
      (user) => value = (
        user: user,
        userIsFromThisDevice: value.userIsFromThisDevice,
        authProblem: value.authProblem,
      ),
    );
    follow(
      authStore.watchFromThisDevice(),
      (fromThisDevice) => value = (
        user: value.user,
        userIsFromThisDevice: fromThisDevice,
        authProblem: value.authProblem,
      ),
    );
    follow(
      authStore.watchProblem(),
      (problem) => value = (
        user: value.user,
        userIsFromThisDevice: value.userIsFromThisDevice,
        authProblem: problem,
      ),
    );
  }

  /// Who is signed in, as far as this device knows.
  UserInfo? get user => value.user;

  /// Whether [user] is the copy this device kept, rather than what the
  /// provider says right now. It is the difference between "these are your
  /// roles" and "these were your roles the last time we could ask".
  bool get userIsFromThisDevice => user != null && value.userIsFromThisDevice;

  /// What went wrong the last time this app tried to find out who the user is.
  ///
  /// Worth keeping rather than only logging. Every page decides what to show
  /// from the roles the provider sent, so a sign-in that failed looks exactly
  /// like an account with no roles — and telling a player they have not been
  /// given access, when what actually happened is that the app was pointed at
  /// the wrong port, is the least helpful thing it could say.
  String? get authProblem => value.authProblem;
}
