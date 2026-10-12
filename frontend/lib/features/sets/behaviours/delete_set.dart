import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sets/storage/sets_database.dart';

class DeleteSet({
  super.monitor,
  required final SetsApi api,
  required final SetsDatabase db,
}) extends Behaviour<String, void> {
  @override
  String get description => 'deleting a set';

  @override
  Future<void> action(String setId, BehaviourTrack? track) async {
    track?.addAttribute('set', setId);
    await api.deleteSet(setId);
    await db.remove(setId);
  }
}
