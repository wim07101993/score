import 'package:behaviour/behaviour.dart';
import 'package:flutter/foundation.dart';
import 'package:score/features/auth/storage/auth_store.dart';
import 'package:score/features/auth/storage/oidc_api.dart';

/// Goes on as who this device last knew, before the first page is drawn.
///
/// Answers false when that will not do, and the provider has to be asked
/// with [UpdateAuth] before anything is shown. On the web signing in is a
/// redirect, which does not keep anything waiting — and the code a redirect
/// came back with is best dealt with before any page is drawn, since dealing
/// with it may put the user on another page altogether. So is a first start,
/// which has nobody to show anything for until it has asked.
///
/// On a device it can be a browser left open for minutes, and the scores
/// already downloaded are no less readable for the user not having signed
/// in yet. So the app starts with who this device last knew, and asks the
/// provider once it is showing. So does the web, with nothing to finish:
/// asking is two round trips, which on a venue's wifi is a long time to
/// look at a spinner in front of scores that are already here.
class GoOnAsKeptUser({
  super.monitor,
  required final OidcApi oidc,
  required final AuthStore authStore,
}) extends BehaviourWithoutInput<bool> {
  @override
  String get description => 'going on as who this device last knew';

  @override
  Future<bool> action(BehaviourTrack? track) async {
    final kept = await oidc.keptUserInfo();
    if (kIsWeb && (kept == null || await oidc.isFinishingASignIn())) {
      return false;
    }
    await authStore.keepFromThisDevice(fromThisDevice: kept != null);
    return true;
  }
}
