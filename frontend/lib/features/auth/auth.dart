import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/collections/repository.dart';
import 'package:score/features/sets/repository.dart';

final _log = GetIt.I<Logger>(param1: 'Auth');

/// Who uses this device, as far as it knows.
///
/// Every page decides what to show from the roles in [user], and listens to
/// this to hear when that changes.
class Auth extends ChangeNotifier {
  Auth(this._oidc, this._sets, this._collections);

  final OidcApi _oidc;
  final SetsRepository _sets;
  final CollectionsRepository _collections;

  /// Who is signed in, as far as this device knows.
  UserInfo? user;

  /// Whether the user above is the copy this device kept, rather than what the
  /// provider says right now. It is the difference between "these are your
  /// roles" and "these were your roles the last time we could ask".
  bool userIsFromThisDevice = false;

  /// What went wrong the last time this app tried to find out who the user is.
  ///
  /// Worth keeping rather than only logging. Every page decides what to show
  /// from the roles the provider sent, so a sign-in that failed looks exactly
  /// like an account with no roles — and telling a player they have not been
  /// given access, when what actually happened is that the app was pointed at
  /// the wrong port, is the least helpful thing it could say.
  Object? authProblem;

  /// How many times the user signed out: see [signOut]. A sign-in check that
  /// was out when it happened drops its answer rather than taking it.
  var _signOuts = 0;

  /// Goes on as who this device last knew, before the first page is drawn.
  ///
  /// Returns false when that will not do, and the provider has to be asked
  /// with [updateAuth] before anything is shown. On the web signing in is a
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
  Future<bool> goOnAsKeptUser() async {
    final kept = await _oidc.keptUserInfo();
    if (kIsWeb && (kept == null || await _oidc.isFinishingASignIn())) {
      return false;
    }
    user = kept;
    userIsFromThisDevice = kept != null;
    notifyListeners();
    return true;
  }

  /// Asks the provider who the user is, falling back on what this device was
  /// last told.
  ///
  /// A provider that cannot be reached is not a user who is signed out: a
  /// player on a stage with no signal still has to be able to read the scores
  /// they downloaded. So the copy this device kept is used, and the app says so
  /// rather than pretending it just asked.
  ///
  /// A sign-in that failed is not started again on its own — see
  /// [OidcApi.signInFailure]. [retry] is the user asking for it anyway.
  Future<UserInfo?> updateAuth({bool retry = false}) async {
    final signOutsBefore = _signOuts;
    if (retry) {
      _oidc.forgetSignInFailure();
    }
    if (!await _oidc.canBeReached()) {
      _log.info('the sign-in provider cannot be reached; going on as who this'
          ' device last knew');
      user = await _oidc.keptUserInfo();
      userIsFromThisDevice = true;
      authProblem = null;
      notifyListeners();
      return user;
    }

    try {
      final asked = await _oidc.getUserInfo();
      // The user signed out while the provider was being asked; what it said
      // is about them, and the device is nobody's now.
      if (_signOuts != signOutsBefore) {
        return null;
      }
      if (asked != null) {
        await _takeTheDataHereFor(asked);
        _log.info('signed in as ${asked.subject}');
        user = asked;
        userIsFromThisDevice = false;
      } else {
        // No token could be had — the sign-in was cancelled, timed out, or
        // failed — which says nothing about who uses this device. The copy it
        // kept is still who it was, and the scores downloaded for them are no
        // less readable for it; only forgetting the user forgets them.
        _log.info('no sign-in to ask the provider with; going on as who this'
            ' device last knew');
        user = await _oidc.keptUserInfo();
        userIsFromThisDevice = user != null;
      }
      authProblem = _oidc.signInFailure;
    } catch (error, stackTrace) {
      if (_signOuts != signOutsBefore) {
        return null;
      }
      _log.warning('failed to ask the provider who this is', error, stackTrace);
      user = await _oidc.keptUserInfo();
      userIsFromThisDevice = true;
      authProblem = error;
    }
    notifyListeners();
    return user;
  }

  Future<void> forgetUser() async {
    await _oidc.forgetUser();
    user = null;
    userIsFromThisDevice = false;
    authProblem = null;
    notifyListeners();
  }

  /// Signs the user out of this device, and forgets the sets and collections
  /// they kept here — what they had not sent yet included, which the page
  /// asks about first.
  ///
  /// Their sets are theirs, and some of them nobody else may read; a device
  /// that is left to the next person with them on it has handed them over.
  /// The scores stay: every score viewer may read them, and they are what the
  /// next one to sign in will want on a stage with no network.
  Future<void> signOut() async {
    _signOuts++;
    await _oidc.signOut();
    await _sets.forgetAll();
    await _collections.forgetAll();
    await _oidc.keepDataOwner(null);
    user = null;
    userIsFromThisDevice = false;
    authProblem = null;
    notifyListeners();
  }

  /// Says so when a sync left this device with no token and nothing to get
  /// one with: the API refused it, and there was no refresh token behind it.
  /// The repositories forget such a token themselves, so this is asked after
  /// every sync rather than only when one throws.
  Future<void> sayIfNoLongerSignedIn() async {
    if (user == null || authProblem != null || await _oidc.holdsAToken()) {
      return;
    }
    authProblem = OidcException(
      'the server no longer takes this sign-in; sign in again to sync',
    );
    notifyListeners();
  }

  /// Makes the sets and collections on this device [asked]'s, forgetting what
  /// somebody else left here first.
  ///
  /// "Sign in again" forgets the tokens and keeps the data, which is right for
  /// the same user coming back and wrong for the next one: pushed with their
  /// token, the last user's sets would be created as theirs, and their pull
  /// would start where the last user's left off. Nothing is synced in between
  /// — see [OidcApi.holdsTheDataOfTheSignedInUser].
  Future<void> _takeTheDataHereFor(UserInfo asked) async {
    final subject = asked.subject;
    if (subject == null) return;
    final owner = await _oidc.dataOwner();
    if (owner == subject) return;
    if (owner != null) {
      _log.info('another user signed in; forgetting the sets and collections'
          ' the last one left on this device');
      await _sets.forgetAll();
      await _collections.forgetAll();
    }
    await _oidc.keepDataOwner(subject);
  }
}
