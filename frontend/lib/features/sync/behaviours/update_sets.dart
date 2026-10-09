import 'package:behaviour/behaviour.dart';
import 'package:score/features/sets/behaviours/sets_engine.dart';
import 'package:score/features/sets/storage/sets_api.dart';
import 'package:score/features/sync/behaviours/api_sync.dart';
import 'package:score/features/sync/behaviours/one_at_a_time.dart';

/// Squares the sets with the API, which is also when whatever was written
/// while it could not be reached is sent.
class UpdateSets({
  super.monitor,
  required final SetsApi api,
  required final SetsEngine engine,
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
      sync: engine.syncWithApi,
    ),
  );
}
