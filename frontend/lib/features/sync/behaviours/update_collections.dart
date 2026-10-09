import 'package:behaviour/behaviour.dart';
import 'package:score/features/collections/behaviours/collections_engine.dart';
import 'package:score/features/collections/storage/collections_api.dart';
import 'package:score/features/sync/behaviours/api_sync.dart';
import 'package:score/features/sync/behaviours/one_at_a_time.dart';

/// Squares the collections with the API, which is also when whatever was
/// written while it could not be reached is sent.
class UpdateCollections({
  super.monitor,
  required final CollectionsApi api,
  required final CollectionsEngine engine,
  required final ApiSync apiSync,
  required final OneAtATime oneAtATime,
}) extends BehaviourWithoutInput<void> {
  @override
  String get description => 'updating the collections';

  @override
  Future<void> action(BehaviourTrack? track) => oneAtATime(
    'collections',
    () => apiSync(
      what: 'syncing the collections',
      apiCanBeReached: api.canBeReached,
      sync: engine.syncWithApi,
    ),
  );
}
