import 'package:behaviour/behaviour.dart';
import 'package:logging/logging.dart';
import 'package:score/features/auth/behaviours/sign_outs.dart';
import 'package:score/features/auth/storage/auth_store.dart';
import 'package:score/features/auth/storage/oidc_api.dart';
import 'package:score/features/collections/behaviours/forget_collections.dart';
import 'package:score/features/sets/behaviours/forget_sets.dart';

class const UpdateAuthParams({
  /// The user asking for a sign-in that failed to be started over: see
  /// [OidcApi.signInFailure].
  final bool retry = false,
});

/// Asks the provider who the user is, falling back on what this device was
/// last told, and answers with who that is.
///
/// A provider that cannot be reached is not a user who is signed out: a
/// player on a stage with no signal still has to be able to read the scores
/// they downloaded. So the copy this device kept is used, and the app says so
/// rather than pretending it just asked.
///
/// A sign-in that failed is not started again on its own — see
/// [OidcApi.signInFailure].
class UpdateAuth({
  super.monitor,
  required final Logger logger,
  required final OidcApi oidc,
  required final AuthStore authStore,
  required final SignOuts signOuts,
  required final ForgetSets forgetSets,
  required final ForgetCollections forgetCollections,
}) extends Behaviour<UpdateAuthParams, UserInfo?> {
  @override
  String get description => 'asking the provider who the user is';

  @override
  Future<UserInfo?> action(
    UpdateAuthParams input,
    BehaviourTrack? track,
  ) async {
    final signOutsBefore = signOuts.count;
    if (input.retry) {
      oidc.forgetSignInFailure();
    }
    if (!await oidc.canBeReached()) {
      logger.info(
        'the sign-in provider cannot be reached; going on as who this'
        ' device last knew',
      );
      await authStore.keepFromThisDevice(fromThisDevice: true);
      await authStore.keepProblem(null);
      return oidc.keptUserInfo();
    }

    try {
      final asked = await oidc.getUserInfo();
      // The user signed out while the provider was being asked; what it said
      // is about them, and the device is nobody's now.
      if (signOuts.count != signOutsBefore) {
        return null;
      }
      final UserInfo? user;
      if (asked != null) {
        await _takeTheDataHereFor(asked, track);
        logger.info('signed in as ${asked.subject}');
        user = asked;
        await authStore.keepFromThisDevice(fromThisDevice: false);
      } else {
        // No token could be had — the sign-in was cancelled, timed out, or
        // failed — which says nothing about who uses this device. The copy it
        // kept is still who it was, and the scores downloaded for them are no
        // less readable for it; only forgetting the user forgets them.
        logger.info(
          'no sign-in to ask the provider with; going on as who this'
          ' device last knew',
        );
        user = await oidc.keptUserInfo();
        await authStore.keepFromThisDevice(fromThisDevice: user != null);
      }
      await authStore.keepProblem(oidc.signInFailure);
      return user;
    } catch (error, stackTrace) {
      if (signOuts.count != signOutsBefore) {
        return null;
      }
      logger.warning(
        'failed to ask the provider who this is',
        error,
        stackTrace,
      );
      await authStore.keepFromThisDevice(fromThisDevice: true);
      await authStore.keepProblem(error);
      return oidc.keptUserInfo();
    }
  }

  /// Makes the sets and collections on this device [asked]'s, forgetting what
  /// somebody else left here first.
  ///
  /// "Sign in again" forgets the tokens and keeps the data, which is right for
  /// the same user coming back and wrong for the next one: pushed with their
  /// token, the last user's sets would be created as theirs, and their pull
  /// would start where the last user's left off. Nothing is synced in between
  /// — see [OidcApi.holdsTheDataOfTheSignedInUser].
  Future<void> _takeTheDataHereFor(
    UserInfo asked,
    BehaviourTrack? track,
  ) async {
    final subject = asked.subject;
    if (subject == null) return;
    final owner = await oidc.dataOwner();
    if (owner == subject) return;
    if (owner != null) {
      logger.info(
        'another user signed in; forgetting the sets and collections'
        ' the last one left on this device',
      );
      await forgetSets.action(track);
      await forgetCollections.action(track);
    }
    await oidc.keepDataOwner(subject);
  }
}
