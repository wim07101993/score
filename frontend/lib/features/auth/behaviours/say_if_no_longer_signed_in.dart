import 'package:behaviour/behaviour.dart';
import 'package:score/features/auth/storage/auth_store.dart';
import 'package:score/features/auth/storage/oidc_api.dart';

/// Says so when a sync left this device with no token and nothing to get one
/// with: the API refused it, and there was no refresh token behind it. The
/// syncs forget such a token themselves, so this is asked after every sync
/// rather than only when one throws.
class SayIfNoLongerSignedIn({
  super.monitor,
  required final OidcApi oidc,
  required final AuthStore authStore,
}) extends BehaviourWithoutInput<void> {
  @override
  String get description => 'checking the sign-in still holds';

  @override
  Future<void> action(BehaviourTrack? track) async {
    if (await oidc.keptUserInfo() == null ||
        await authStore.readProblem() != null ||
        await oidc.holdsAToken()) {
      return;
    }
    await authStore.keepProblem(
      OidcException(
        message:
            'the server no longer takes this sign-in; sign in again to sync',
      ),
    );
  }
}
