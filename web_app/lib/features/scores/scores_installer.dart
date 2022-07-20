import 'package:score/app_get_it_extensions.dart';
import 'package:score/features/scores/behaviours/search_scores.dart';
import 'package:score/features/scores/change_notifiers/search_string_notifier.dart';
import 'package:score/shared/behaviours/standard_behaviour_monitor.dart';

class ScoresInstaller implements Installer {
  const ScoresInstaller();

  @override
  Future<void> initialize(GetIt getIt) {
    return Future.value();
  }

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerFactory(() => SearchStringNotifier());
    getIt.registerFactory(() => SearchScores(
        algolia: getIt(), monitor: getIt.monitor<StandardBehaviourTrack>()));
  }
}
