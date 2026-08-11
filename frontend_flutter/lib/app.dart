import 'package:flutter/material.dart';

import 'config.dart';
import 'data/local_store.dart';
import 'data/settings.dart';
import 'domains/auth/oidc_api.dart';
import 'domains/scores/api.dart';
import 'domains/scores/repository.dart';
import 'domains/sets/api.dart';
import 'domains/sets/repository.dart';

/// Everything the app is made of, wired together once.
///
/// A page reads what is stored and asks for a sync; it never waits on the
/// network to draw. Which is why the repositories are built before anything is
/// shown and the syncs are started after: what is on this device is on screen
/// straight away, and whatever the server has to add arrives when it arrives.
class App extends ChangeNotifier {
  App._(this.config, this.store, this.settings, this.oidc, this.scoresApi,
      this.setsApi, this.scores, this.sets);

  final Config config;
  final LocalStore store;

  /// What this device prefers. Notifies on its own — the theme changes without
  /// anything else about the app having changed.
  final Settings settings;

  final OidcApi oidc;
  final ScoresApi scoresApi;
  final SetsApi setsApi;
  final ScoresRepository scores;
  final SetsRepository sets;

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

    final app = App._(
      config,
      store,
      settings,
      oidc,
      scoresApi,
      setsApi,
      ScoresRepository(store, scoresApi, oidc),
      SetsRepository(store, setsApi, oidc),
    );

    await app.scores.init();
    await app.sets.init();
    await app.updateAuth();
    return app;
  }

  /// Asks the provider who the user is, falling back on what this device was
  /// last told.
  ///
  /// A provider that cannot be reached is not a user who is signed out: a
  /// player on a stage with no signal still has to be able to read the scores
  /// they downloaded. So the copy this device kept is used, and the app says so
  /// rather than pretending it just asked.
  Future<UserInfo?> updateAuth() async {
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
      authProblem = null;
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
}

/// How a page gets hold of the app.
class AppScope extends InheritedNotifier<App> {
  const AppScope({super.key, required App app, required super.child})
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
