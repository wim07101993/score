import 'package:core/core.dart';

import 'behaviour_track.dart';

abstract class Monitor {
  BehaviourTrack createBehaviourTrack(BehaviourMixin behaviour);
}
