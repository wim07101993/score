import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/logging/get_it.dart';
import 'package:score/features/scores/behaviours/sync_scores.dart';

class ScoreSyncer with WidgetsBindingObserver {
  ScoreSyncer({
    required this.userManager,
    required this.bindings,
  });

  static const String _name = 'ScoreSyncer';

  final OidcUserManager userManager;
  final WidgetsBinding bindings;

  StreamSubscription? _userChangesSubscription;

  void start() {
    userManager.userChanges().listen((_) => syncIfLoggedIn());
    bindings.addObserver(this);
    syncIfLoggedIn();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        syncIfLoggedIn();
      default:
        return;
    }
  }

  Future<void> syncIfLoggedIn() async {
    final currentUser = userManager.currentUser;
    if (currentUser == null) {
      return;
    }
    final syncScores = await GetIt.I.getAsync<SyncScores>();
    await syncScores(currentUser).thenWhen(
      (exception) {
        GetIt.I.logger(_name).severe('failed to sync scores', exception);
      },
      (_) {},
    );
  }

  void dispose() {
    _userChangesSubscription?.cancel();
    bindings.removeObserver(this);
  }
}
