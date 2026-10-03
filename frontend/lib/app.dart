import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:score/api.dart';
import 'package:score/background.dart';
import 'package:score/config.dart';
import 'package:score/features/auth/oidc_api.dart';
import 'package:score/features/collections/api.dart';
import 'package:score/features/collections/repository.dart';
import 'package:score/features/scores/api.dart';
import 'package:score/features/scores/repository.dart';
import 'package:score/features/sembast/local_store.dart';
import 'package:score/features/sets/api.dart';
import 'package:score/features/sets/repository.dart';
import 'package:score/features/settings/settings.dart';

final _log = Logger('App');

/// Everything the app is made of, wired together once.
///
/// A page reads what is stored and asks for a sync; it never waits on the
/// network to draw. Which is why the repositories are built before anything is
/// shown and the syncs are started after: what is on this device is on screen
/// straight away, and whatever the server has to add arrives when it arrives.
class App extends ChangeNotifier {
  App._(this.config, this.settings, this.oidc, this.scoresApi,
      this.setsApi, this.collectionsApi, this.scores, this.sets,
      this.collections);

  final Config config;

  /// What this device prefers. Notifies on its own — the theme changes without
  /// anything else about the app having changed.
  final Settings settings;

  final OidcApi oidc;
  final ScoresApi scoresApi;
  final SetsApi setsApi;
  final CollectionsApi collectionsApi;
  final ScoresRepository scores;
  final SetsRepository sets;
  final CollectionsRepository collections;

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

  static Future<App> start() async {
    final config = await Config.load();
    final store = await LocalStore.open();
    final settings = await Settings.load(store);

    // One client for every request the app makes, none of which waits for good.
    final client = TimingOutClient(http.Client());
    final oidc = OidcApi(config.oidc, store, client: client);
    final scoresApi = ScoresApi(config.api, client: client);
    final setsApi = SetsApi(config.api, client: client);
    final collectionsApi = CollectionsApi(config.api, client: client);

    final app = App._(
      config,
      settings,
      oidc,
      scoresApi,
      setsApi,
      collectionsApi,
      ScoresRepository(store, scoresApi, oidc),
      SetsRepository(store, setsApi, oidc),
      CollectionsRepository(store, collectionsApi, oidc),
    );

    await app.scores.init();
    await app.sets.init();
    await app.collections.init();

    final kept = await oidc.keptUserInfo();
    // What a build from before the data had an owner kept here is the user's
    // it kept along with it.
    if (kept?.subject case final subject?
        when await oidc.dataOwner() == null) {
      await oidc.keepDataOwner(subject);
    }
    if (kIsWeb && (kept == null || await oidc.isFinishingASignIn())) {
      // On the web signing in is a redirect, which does not keep anything
      // waiting — and the code a redirect came back with is best dealt with
      // before any page is drawn, since dealing with it may put the user on
      // another page altogether. So is a first start, which has nobody to
      // show anything for until it has asked.
      await app.updateAuth();
    } else {
      // On a device it can be a browser left open for minutes, and the scores
      // already downloaded are no less readable for the user not having signed
      // in yet. So the app starts with who this device last knew, and asks the
      // provider once it is showing. So does the web, with nothing to finish:
      // asking is two round trips, which on a venue's wifi is a long time to
      // look at a spinner in front of scores that are already here.
      app.user = kept;
      app.userIsFromThisDevice = app.user != null;
      inTheBackground(app.updateAuthAndCatchUp());
    }
    return app;
  }

  /// Asks the provider who the user is behind a page that is already showing,
  /// and then fetches what a page drawn before there was anyone to fetch it for
  /// did not: a page asks for its sync once, when it is opened, and a user who
  /// only became a reader of scores after that would otherwise wait for the
  /// next page to be opened.
  ///
  /// [retry] is as for [updateAuth].
  Future<void> updateAuthAndCatchUp({bool retry = false}) async {
    final couldView = user?.isScoreViewer == true;
    await updateAuth(retry: retry);
    if (couldView || user?.isScoreViewer != true) {
      return;
    }
    await updateScores();
    await updateSets();
    await updateCollections();
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
    if (retry) {
      oidc.forgetSignInFailure();
    }
    if (!await oidc.canBeReached()) {
      _log.info('the sign-in provider cannot be reached; going on as who this'
          ' device last knew');
      user = await oidc.keptUserInfo();
      userIsFromThisDevice = true;
      authProblem = null;
      notifyListeners();
      return user;
    }

    try {
      final asked = await oidc.getUserInfo();
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
        user = await oidc.keptUserInfo();
        userIsFromThisDevice = user != null;
      }
      authProblem = oidc.signInFailure;
    } catch (error, stackTrace) {
      _log.warning('failed to ask the provider who this is', error, stackTrace);
      user = await oidc.keptUserInfo();
      userIsFromThisDevice = true;
      authProblem = error;
    }
    notifyListeners();
    return user;
  }

  Future<void> forgetUser() async {
    await oidc.forgetUser();
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
    await oidc.signOut();
    await sets.forgetAll();
    await collections.forgetAll();
    await oidc.keepDataOwner(null);
    user = null;
    userIsFromThisDevice = false;
    authProblem = null;
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
    final owner = await oidc.dataOwner();
    if (owner == subject) return;
    if (owner != null) {
      _log.info('another user signed in; forgetting the sets and collections'
          ' the last one left on this device');
      await sets.forgetAll();
      await collections.forgetAll();
    }
    await oidc.keepDataOwner(subject);
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
      await _sayIfNoLongerSignedIn();
    } catch (error, stackTrace) {
      _log.warning('failed to sync the scores', error, stackTrace);
      await _forgetTokenIfRefused(error);
    }
  }

  Future<void> _syncEveryScore() async {
    await _updateScores();
    if (!await scoresApi.canBeReached() || !await oidc.canBeReached()) {
      return;
    }
    try {
      await scores.forgetWhatTheServerNoLongerHas();
      await _sayIfNoLongerSignedIn();
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
      await _sayIfNoLongerSignedIn();
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
    await _sayIfNoLongerSignedIn();
  }

  /// Says so when a sync left this device with no token and nothing to get
  /// one with: the API refused it, and there was no refresh token behind it.
  /// The repositories forget such a token themselves, so this is asked after
  /// every sync rather than only when one throws.
  Future<void> _sayIfNoLongerSignedIn() async {
    if (user == null || authProblem != null || await oidc.holdsAToken()) {
      return;
    }
    authProblem = OidcException(
      'the server no longer takes this sign-in; sign in again to sync',
    );
    notifyListeners();
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
    // A kind of its own: one asked for while a page's sync of the scores is
    // running would otherwise be folded into the next one of those, and that
    // one does not look for what is gone.
    await _oneAtATime('every score', _syncEveryScore);
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
      await _sayIfNoLongerSignedIn();
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

/// How a page gets hold of the app.
class AppScope extends InheritedNotifier<App> {
  const AppScope({
    super.key,
    required App app,
    required super.child,
  })
      : super(notifier: app);

  static App of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope?.notifier != null, 'no App above this widget');
    return scope!.notifier!;
  }

  /// The app, without asking to be rebuilt when it changes. For a callback that
  /// only wants to *do* something with it.
  static App read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope?.notifier != null, 'no App above this widget');
    return scope!.notifier!;
  }
}
