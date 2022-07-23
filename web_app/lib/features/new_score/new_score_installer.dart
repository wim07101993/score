import 'package:score/app_get_it_extensions.dart';
import 'package:score/features/new_score/behaviours/save_new_score.dart';
import 'package:score/features/new_score/bloc/create_score_wizard_bloc.dart';
import 'package:score/shared/behaviours/standard_behaviour_monitor.dart';

class NewScoreInstaller implements Installer {
  const NewScoreInstaller();

  @override
  Future<void> initialize(GetIt getIt) {
    return Future.value();
  }

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerFactory(() => CreateScoreWizardBloc(saveNewScore: getIt()));
    getIt.registerFactory(() => SaveNewScore(
          monitor: getIt.monitor<StandardBehaviourTrack>(),
          firestore: getIt(),
        ));
  }
}
