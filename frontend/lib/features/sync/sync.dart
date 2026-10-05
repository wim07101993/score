import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:score/features/auth/auth.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/collections/api.dart';
import 'package:score/features/collections/repository.dart';
import 'package:score/features/scores/api.dart';
import 'package:score/features/scores/repository.dart';
import 'package:score/features/sets/api.dart';
import 'package:score/features/sets/repository.dart';

final _log = GetIt.I<Logger>(param1: 'Sync');

/// Squares what is on this device with the API.
///
/// A page reads what is stored and asks for a sync; it never waits on the
/// network to draw. What is on this device is on screen straight away, and
/// whatever the server has to add arrives when it arrives.
class Sync({
  required final Auth auth,
  required final OidcApi oidc,
  required final ScoresApi scoresApi,
  required final SetsApi setsApi,
  required final CollectionsApi collectionsApi,
  required final ScoresRepository scores,
  required final SetsRepository sets,
  required final CollectionsRepository collections,
}) {
  /// Asks the provider who the user is behind a page that is already showing,
  /// and then fetches what a page drawn before there was anyone to fetch it for
  /// did not: a page asks for its sync once, when it is opened, and a user who
  /// only became a reader of scores after that would otherwise wait for the
  /// next page to be opened.
  ///
  /// [retry] is as for [Auth.updateAuth].
  Future<void> updateAuthAndCatchUp({bool retry = false}) async {
    final couldView = auth.user?.isScoreViewer == true;
    await auth.updateAuth(retry: retry);
    if (couldView || auth.user?.isScoreViewer != true) {
      return;
    }
    await updateScores();
    await updateSets();
    await updateCollections();
  }

  final _oneAtATime = OneAtATime();

  /// Squares the scores with the API. Never throws: this is called from pages
  /// that are already drawn, and a sync that cannot happen is not a page that
  /// should break.
  Future<void> updateScores() => _oneAtATime('scores', _updateScores);

  Future<void> _updateScores() async {
    // The provider too, as for the sets: a sync with no token to hand starts a
    // sign-in, and on the web a sign-in is the page leaving for a provider that
    // is not there.
    if (!await scoresApi.canBeReached() || !await oidc.canBeReached()) {
      return;
    }
    try {
      _log.fine('syncing the scores');
      await scores.syncWithApi();
      await auth.sayIfNoLongerSignedIn();
    } catch (error, stackTrace) {
      _log.warning('failed to sync the scores', error, stackTrace);
      await _forgetTokenIfRefused(error);
    }
  }

  /// Not through [_oneAtATime]: one asked for while a page's sync of the
  /// scores is waiting would be folded into that sync, which does not look for
  /// what is gone. The repository runs it after whatever sync is running
  /// instead.
  Future<void> _forgetTheScoresThatAreGone() async {
    if (!await scoresApi.canBeReached() || !await oidc.canBeReached()) {
      return;
    }
    try {
      await scores.forgetWhatTheServerNoLongerHas();
      await auth.sayIfNoLongerSignedIn();
    } catch (error, stackTrace) {
      _log.warning(
          'failed to look for the scores that are gone', error, stackTrace);
      await _forgetTokenIfRefused(error);
    }
  }

  /// Squares the sets with the API, which is also when whatever was written
  /// while it could not be reached is sent.
  Future<void> updateSets() => _oneAtATime('sets', _updateSets);

  Future<void> _updateSets() async {
    if (!await setsApi.canBeReached() || !await oidc.canBeReached()) {
      return;
    }
    try {
      _log.fine('syncing the sets');
      await sets.syncWithApi();
      await auth.sayIfNoLongerSignedIn();
    } catch (error, stackTrace) {
      _log.warning('failed to sync the sets', error, stackTrace);
      await _forgetTokenIfRefused(error);
    }
  }

  /// A token the API refused is spent, however long this device thinks it has
  /// left: revoked, or the session behind it ended somewhere else. It is
  /// forgotten, so that the next sync asks for a fresh one rather than sending
  /// the same one again until it runs out on its own.
  ///
  /// With no refresh token to get the next one with, the user has to sign in
  /// again — which is said, rather than done: a sync does not send anybody to
  /// the provider (see [OidcApi.getActiveAccessToken]), and one that did would
  /// go round for as long as the API refused what the provider handed out.
  Future<void> _forgetTokenIfRefused(Object error) async {
    final status = switch (error) {
      ScoresApiException(:final status) => status,
      SetsApiException(:final status) => status,
      CollectionsApiException(:final status) => status,
      _ => null,
    };
    if (status == 401) {
      await oidc.forgetAccessToken();
    }
    await auth.sayIfNoLongerSignedIn();
  }

  /// Squares the collections with the API, which is also when whatever was
  /// written while it could not be reached is sent.
  Future<void> updateCollections() =>
      _oneAtATime('collections', _updateCollections);

  /// Squares the scores, the sets and the collections with the API, one after
  /// the other: what the player asks for with the sync button. Never throws,
  /// as none of the syncs it is made of do.
  ///
  /// Unlike the sync a page asks for, this also forgets the scores the server
  /// no longer has: see [ScoresRepository.forgetWhatTheServerNoLongerHas].
  Future<void> syncEverything() async {
    await updateScores();
    await _forgetTheScoresThatAreGone();
    await updateSets();
    await updateCollections();
  }

  Future<void> _updateCollections() async {
    if (!await collectionsApi.canBeReached() || !await oidc.canBeReached()) {
      return;
    }
    try {
      _log.fine('syncing the collections');
      await collections.syncWithApi();
      await auth.sayIfNoLongerSignedIn();
    } catch (error, stackTrace) {
      _log.warning('failed to sync the collections', error, stackTrace);
      await _forgetTokenIfRefused(error);
    }
  }
}

/// Runs one sync of a kind at a time.
///
/// Every page that opens asks for the syncs it shows, and a link into a song
/// of a set opens four of them at once — each of which would otherwise list
/// the same changes and fetch the same documents side by side. One asked for
/// while one is running goes once after it, however many ask: what it reads
/// may have changed after the running one read it.
@visibleForTesting
class OneAtATime {
  /// The sync of each kind that is running, and the one to run after it.
  final Map<String, Future<void>> _running = {};
  final Map<String, Future<void>> _next = {};

  Future<void> call(String kind, Future<void> Function() sync) {
    final running = _running[kind];
    if (running == null) {
      // A block body, not an arrow: `remove` hands back the future it removes,
      // which is this one, and a whenComplete that returns it waits on itself.
      return _running[kind] = sync().whenComplete(() {
        _running.remove(kind);
      });
    }
    return _next[kind] ??= running.then((_) {
      _next.remove(kind);
      return call(kind, sync);
    });
  }
}
