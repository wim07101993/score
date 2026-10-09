import 'package:behaviour/behaviour.dart';
import 'package:score/features/auth/behaviours/sign_outs.dart';
import 'package:score/features/auth/storage/auth_store.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/features/collections/behaviours/forget_collections.dart';
import 'package:score/features/sets/behaviours/forget_sets.dart';

/// Signs the user out of this device, and forgets the sets and collections
/// they kept here — what they had not sent yet included, which the page asks
/// about first.
///
/// Their sets are theirs, and some of them nobody else may read; a device
/// that is left to the next person with them on it has handed them over.
/// The scores stay: every score viewer may read them, and they are what the
/// next one to sign in will want on a stage with no network.
class SignOut({
  super.monitor,
  required final OidcApi oidc,
  required final AuthStore authStore,
  required final SignOuts signOuts,
  required final ForgetSets forgetSets,
  required final ForgetCollections forgetCollections,
}) extends BehaviourWithoutInput<void> {
  @override
  String get description => 'signing out';

  @override
  Future<void> action(BehaviourTrack? track) async {
    signOuts.count++;
    await oidc.signOut();
    await forgetSets.action(track);
    await forgetCollections.action(track);
    await oidc.keepDataOwner(null);
    await authStore.keepFromThisDevice(fromThisDevice: false);
    await authStore.keepProblem(null);
  }
}
