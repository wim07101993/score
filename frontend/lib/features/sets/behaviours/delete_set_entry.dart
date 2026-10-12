import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/behaviours/get_set.dart';
import 'package:score/features/sets/models.dart';
import 'package:score/features/sets/storage/sets_api.dart';

class const DeleteSetEntryParams({
  required final String setId,
  required final String entryId,
});

class DeleteSetEntry({
  super.monitor,
  required final SetsApi api,
  required final FetchSet fetch,
}) extends Behaviour<DeleteSetEntryParams, ScoreSet> {
  @override
  String get description => 'taking a song out of a set';

  @override
  Future<ScoreSet> action(
    DeleteSetEntryParams input,
    BehaviourTrack? track,
  ) async {
    track?.addAttribute('set', input.setId);
    await api.deleteEntry(input.setId, input.entryId);
    return await fetch.action(input.setId, track) ??
        (throw Exception('failed to read back the set which was just changed'));
  }
}
