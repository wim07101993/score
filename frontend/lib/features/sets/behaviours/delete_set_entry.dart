import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/behaviours/sets_engine.dart';
import 'package:score/features/sets/models.dart';

class const DeleteSetEntryParams({
  required final String setId,
  required final String entryId,
});

/// Takes one score out of a set and closes the running order up around it.
///
/// What every player said about how they look at it goes with it: it was
/// about a song that is no longer played.
class DeleteSetEntry({
  super.monitor,
  required final SetsEngine engine,
}) extends Behaviour<DeleteSetEntryParams, ScoreSet> {
  @override
  String get description => 'taking a song out of a set';

  @override
  Future<ScoreSet> action(DeleteSetEntryParams input, BehaviourTrack? track) {
    track?.addAttribute('set', input.setId);
    return engine.deleteEntry(input.setId, input.entryId);
  }
}
