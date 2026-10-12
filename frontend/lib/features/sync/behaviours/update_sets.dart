import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/behaviours/sync_sets.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sync/behaviours/api_sync.dart';
import 'package:score/features/sync/behaviours/one_at_a_time.dart';

class UpdateSets({
  super.monitor,
  required final SetsApi api,
  required final SyncSets syncSets,
  required final ApiSync apiSync,
  required final OneAtATime oneAtATime,
}) extends BehaviourWithoutInput<void> {
  @override
  String get description => 'updating the sets';

  @override
  Future<void> action(BehaviourTrack? track) => oneAtATime(
    'sets',
    () => apiSync(
      what: 'syncing the sets',
      apiCanBeReached: api.canBeReached,
      sync: () => syncSets.action(track),
    ),
  );
}
