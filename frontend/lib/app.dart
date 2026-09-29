import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

/// Everything the app is made of, wired together once.
///
/// A page reads what is stored and asks for a sync; it never waits on the
/// network to draw. Which is why the repositories are built before anything is
/// shown and the syncs are started after: what is on this device is on screen
/// straight away, and whatever the server has to add arrives when it arrives.
class App extends ChangeNotifier {
  App._(this.config, this.store, this.settings, this.oidc, this.scoresApi,
      this.setsApi, this.collectionsApi, this.scores, this.sets,
      this.collections);

  final Config config;
  final LocalStore store;

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

    final oidc = OidcApi(config.oidc, store);
    final scoresApi = ScoresApi(config.api);
    final setsApi = SetsApi(config.api);
    final collectionsApi = CollectionsApi(config.api);

    final app = App._(
      config,
      store,
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

    if (kIsWeb) {
      // On the web signing in is a redirect, which does not keep anything
      // waiting — and the code a redirect came back with is best dealt with
      // before any page is drawn, since dealing with it may put the user on
      // another page altogether.
      await app.updateAuth();
    } else {
      // On a device it can be a browser left open for minutes, and the scores
      // already downloaded are no less readable for the user not having signed
      // in yet. So the app starts with who this device last knew, and asks the
      // provider once it is showing.
      app.user = await oidc.keptUserInfo();
      app.userIsFromThisDevice = app.user != null;
      unawaited(app._updateAuthAfterStart());
    }
    return app;
  }

  /// Signs in behind a page that is already showing, and then fetches what a
  /// page that was drawn before there was anyone to fetch it for did not.
  Future<void> _updateAuthAfterStart() async {
    final couldView = user?.isScoreViewer == true;
    await updateAuth();
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
      user = await oidc.keptUserInfo();
      userIsFromThisDevice = true;
      authProblem = null;
      notifyListeners();
      return user;
    }

    try {
      user = await oidc.getUserInfo();
      userIsFromThisDevice = false;
      authProblem = oidc.signInFailure;
    } catch (error) {
      debugPrint('failed to ask the provider who this is: $error');
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

  /// Squares the scores with the API. Never throws: this is called from pages
  /// that are already drawn, and a sync that cannot happen is not a page that
  /// should break.
  Future<void> updateScores() async {
    if (!await scoresApi.canBeReached()) {
      return;
    }
    try {
      await scores.syncWithApi();
    } catch (error) {
      debugPrint('failed to sync the scores: $error');
    }
  }

  /// Squares the sets with the API, which is also when whatever was written
  /// while it could not be reached is sent.
  Future<void> updateSets() async {
    if (!await setsApi.canBeReached() || !await oidc.canBeReached()) {
      return;
    }
    try {
      await sets.syncWithApi();
    } catch (error) {
      debugPrint('failed to sync the sets: $error');
    }
  }

  /// Squares the collections with the API, which is also when whatever was
  /// written while it could not be reached is sent.
  Future<void> updateCollections() async {
    if (!await collectionsApi.canBeReached() || !await oidc.canBeReached()) {
      return;
    }
    try {
      await collections.syncWithApi();
    } catch (error) {
      debugPrint('failed to sync the collections: $error');
    }
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
