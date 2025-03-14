import 'package:behaviour/behaviour.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:oidc/oidc.dart';
import 'package:score/features/logging/get_it.dart';
import 'package:score/features/scores/behaviours/fetch_scores_if_old.dart';

void registerScoreDependencies() {
  GetIt.I.registerLazySingletonAsync(
    () async => FetchScoresIfOld(
      monitor: GetIt.I(),
      database: await GetIt.I.getAsync(),
      user: GetIt.I(),
      searcherClient: GetIt.I(),
    ),
  );
  GetIt.I.registerLazySingleton(
    () => ScoreSyncer(
      user: GetIt.I(),
      bindings: WidgetsFlutterBinding.ensureInitialized(),
    ),
  );
}

class ScoreSyncer with WidgetsBindingObserver {
  const ScoreSyncer({
    required this.user,
    required this.bindings,
  });

  static const String _name = 'ScoreSyncer';

  final ValueListenable<OidcUser?> user;
  final WidgetsBinding bindings;

  void start() {
    user.addListener(sync);
    bindings.addObserver(this);
    sync();
  }

  Future<void> sync() async {
    final fetchScoresIfOld = await GetIt.I.getAsync<FetchScoresIfOld>();
    fetchScoresIfOld().thenWhen(
      (ex) => GetIt.I.logger(_name).severe('failed to fetch scores', ex),
      (_) {},
    );
  }

  void dispose() {
    user.removeListener(sync);
    bindings.removeObserver(this);
  }
}
