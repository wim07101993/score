import 'dart:async';

import 'package:behaviour/behaviour.dart';
import 'package:score/features/scores/storage/scores_api.dart';

class CanConnectToApi({
  required super.monitor,
  required final ScoresApi api,
}) extends BehaviourWithoutInput<bool> {
  @override
  Future<bool> action(BehaviourTrack? track) {
    return api.canBeReached();
  }
}
