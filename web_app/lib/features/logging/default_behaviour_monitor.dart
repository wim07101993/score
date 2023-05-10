import 'package:behaviour/behaviour.dart';
import 'package:get_it/get_it.dart';
import 'package:score/features/logging/behaviour_tracks/logging_behaviour_track.dart';
import 'package:score/shared/dependency_management/get_it_extensions.dart';

class DefaultBehaviourMonitor implements BehaviourMonitor {
  const DefaultBehaviourMonitor({
    required this.getIt,
  });

  final GetIt getIt;

  @override
  BehaviourTrack? createBehaviourTrack(BehaviourMixin behaviour) {
    return LoggingBehaviourTrack(
      behaviour: behaviour,
      logger: getIt.logger(behaviour.runtimeType.toString()),
    );
  }
}
