import 'package:score/app_get_it_extensions.dart';
import 'package:score/features/new_score/behaviours/save_new_score.dart';
import 'package:score/shared/behaviours/standard_behaviour_monitor.dart';
import 'package:score/shared/models/score.dart';

class NewScoreInstaller implements Installer {
  const NewScoreInstaller();

  @override
  Future<void> initialize(GetIt getIt) {
    return Future.value();
  }

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerFactory(() => EditableScore.empty());
    getIt.registerFactory(() => SaveNewScore(
          monitor: getIt.monitor<StandardBehaviourTrack>(),
          firestore: getIt(),
        ));
  }
}
