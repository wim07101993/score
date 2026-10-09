import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/behaviours/sets_engine.dart';

/// Marks the set as deleted here, and tells the server as soon as it can.
///
/// It is kept rather than dropped, the same way the server keeps it: a sync
/// only asks about what changed since the last one, so a set that was simply
/// forgotten here would be fetched straight back in as something new.
class DeleteSet({
  super.monitor,
  required final SetsEngine engine,
}) extends Behaviour<String, void> {
  @override
  String get description => 'deleting a set';

  @override
  Future<void> action(String setId, BehaviourTrack? track) {
    track?.addAttribute('set', setId);
    return engine.delete(setId);
  }
}
