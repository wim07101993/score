import 'package:behaviour/behaviour.dart';
import 'package:score/features/auth/storage/auth_store.dart';
import 'package:score/features/auth/storage/oidc_api.dart';

class ForgetUser({
  super.monitor,
  required final OidcApi oidc,
  required final AuthStore authStore,
}) extends BehaviourWithoutInput<void> {
  @override
  String get description => 'forgetting who is signed in';

  @override
  Future<void> action(BehaviourTrack? track) async {
    await oidc.forgetUser();
    await authStore.keepFromThisDevice(fromThisDevice: false);
    await authStore.keepProblem(null);
  }
}
