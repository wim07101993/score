import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/behaviours/sets_engine.dart';

/// Forgets every set on this device, what is owed about them included, for a
/// device that is handed to somebody else.
class ForgetSets({
  super.monitor,
  required final SetsEngine engine,
}) extends BehaviourWithoutInput<void> {
  @override
  String get description => 'forgetting the sets on this device';

  @override
  Future<void> action(BehaviourTrack? track) => engine.forgetAll();
}
