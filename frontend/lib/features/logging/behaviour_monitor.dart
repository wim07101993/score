import 'package:behaviour/behaviour.dart';
import 'package:get_it/get_it.dart';

class GetItBehaviourMonitor implements BehaviourMonitor {
  const GetItBehaviourMonitor();

  @override
  BehaviourTrack? createBehaviourTrack(BehaviourMixin behaviour) {
    return GetIt.I<BehaviourTrack>(param1: behaviour);
  }
}
